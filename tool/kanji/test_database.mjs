// Local PostgreSQL/WASM harness. Does not connect to or modify Supabase cloud.
// Bootstrap dependency once: python tool/kanji/prepare_test_db.py
import { PGlite } from './.cache/package/dist/index.js';
import { readFile, readdir, writeFile } from 'node:fs/promises';
import { performance } from 'node:perf_hooks';

const db = new PGlite();
let legacySnapshot;
let beforeDecompositions;
try {
  await db.exec(`
    create role anon;
    create role authenticated;
    create schema auth;
    create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql stable as
      $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
    grant usage on schema auth, public to authenticated, anon;
    grant execute on function auth.uid() to authenticated, anon;
  `);
  for (const file of (await readdir('supabase/migrations')).filter(f => f.endsWith('.sql')).sort()) {
    if (file >= '202609090001') continue; // Verify historical migrations before the deliberate rebuild.
    if (file === '202609080001_kanji_decompositions.sql') {
      beforeDecompositions = (await db.query(`select
        (select jsonb_agg(t order by kanji_id, occurrence_id) from public.kanji_component_occurrences t) as occurrences,
        (select jsonb_agg(t order by kanji_id, radical_id, component_form) from public.kanji_components t) as components,
        public.get_user_kanji_snapshot() as snapshot`)).rows[0];
    }
    let sql = await readFile(`supabase/migrations/${file}`, 'utf8');
    // PGlite ships gen_random_uuid in core, but does not bundle pgcrypto.
    sql = sql.replace('create extension if not exists pgcrypto;', '');
    await db.exec(sql);
    console.log(`Applied ${file}`);
    if (file === '202609050003_seed_kanji_catalog.sql') {
      await db.exec(`
        insert into auth.users(id) values ('aaaaaaaa-0000-0000-0000-000000000004');
        insert into public.folders(id,user_id,name) values ('bbbbbbbb-0000-0000-0000-000000000004','aaaaaaaa-0000-0000-0000-000000000004','migration preservation');
        insert into public.vocabulary(user_id,folder_id,kanji,kana,romaji,meaning) values ('aaaaaaaa-0000-0000-0000-000000000004','bbbbbbbb-0000-0000-0000-000000000004','機森','かな','test','test');
        select set_config('request.jwt.claim.sub','aaaaaaaa-0000-0000-0000-000000000004',false);
        select public.recalculate_user_kanji_and_radical_stats();
      `);
      legacySnapshot = (await db.query('select public.get_user_kanji_snapshot() as snapshot')).rows[0].snapshot;
    }
  }
  const afterDecompositions = (await db.query(`select
    (select jsonb_agg(t order by kanji_id, occurrence_id) from public.kanji_component_occurrences t) as occurrences,
    (select jsonb_agg(t order by kanji_id, radical_id, component_form) from public.kanji_components t) as components,
    public.get_user_kanji_snapshot() as snapshot`)).rows[0];
  if (JSON.stringify(beforeDecompositions) !== JSON.stringify(afterDecompositions)) {
    throw new Error('Hierarchical catalog changed v2 components or statistics');
  }
  await db.exec(await readFile('supabase/tests/fixtures/kanji_decompositions_assertions.sql', 'utf8'));
  console.log('PASS: hierarchical trees, RLS and unchanged v2 statistics/occurrences.');
  const afterMigration = (await db.query('select public.get_user_kanji_snapshot() as snapshot')).rows[0].snapshot;
  if (afterMigration.overview.component_version !== 1) throw new Error('Migration relabeled a legacy snapshot');
  const migratedRadicalForms = afterMigration.radical_forms;
  delete afterMigration.radical_forms;
  delete afterMigration.overview.component_version;
  if (JSON.stringify(afterMigration) !== JSON.stringify(legacySnapshot)) throw new Error('Migration changed legacy snapshot counts/timestamps');
  if (!Array.isArray(migratedRadicalForms) || migratedRadicalForms.length === 0) throw new Error('Migration did not add radical forms');
  await db.exec(`
    insert into public.srs_progress(vocab_id,user_id,level,correct_count,wrong_count)
    select id,user_id,3,7,2 from public.vocabulary
    on conflict (vocab_id) do update set level=3,correct_count=7,wrong_count=2;
    insert into public.user_learning_settings(user_id,session_size)
    values ('aaaaaaaa-0000-0000-0000-000000000004',17);
    insert into public.device_preferences(user_id,device_id,theme_mode)
    values ('aaaaaaaa-0000-0000-0000-000000000004','preservation-test','dark');
  `);
  const protectedTables = ['auth.users', 'public.vocabulary', 'public.folders',
    'public.srs_progress', 'public.user_learning_settings', 'public.device_preferences'];
  const protectedSnapshot = async () => Promise.all(protectedTables.map(async table =>
    (await db.query(`select coalesce(jsonb_agg(to_jsonb(t) order by to_jsonb(t)::text),'[]') as data from ${table} t`)).rows[0].data));
  const beforeTaxonomy = await protectedSnapshot();
  await db.exec(await readFile('supabase/migrations/202609090001_kanji_taxonomy_v3.sql', 'utf8'));
  await db.exec(await readFile('supabase/migrations/202609090002_sort_filter_radical_forms.sql', 'utf8'));
  await db.exec(await readFile('supabase/migrations/202609170001_kanji_radical_statistics_v4.sql', 'utf8'));
  if (JSON.stringify(beforeTaxonomy) !== JSON.stringify(await protectedSnapshot())) {
    throw new Error('Taxonomy migration changed protected learning/account data');
  }
  const reset = (await db.query('select public.get_user_kanji_snapshot() as snapshot')).rows[0].snapshot;
  if (reset.overview !== null || reset.kanji.length || reset.radicals.length) throw new Error('Kanji statistics were not reset');
  console.log('PASS: taxonomy migrations preserve complete vocabulary, folders, SRS, settings, device preferences and accounts; only Kanji stats reset.');
  await db.exec(await readFile('supabase/tests/fixtures/kanji_taxonomy_assertions.sql', 'utf8'));
  await db.exec("delete from auth.users where id='aaaaaaaa-0000-0000-0000-000000000004'; select set_config('request.jwt.claim.sub','',false);");
  console.log('PASS: historical migrations preserved v1 snapshot; taxonomy rebuilds deliberately clear only Kanji statistics.');
  await db.exec(`
    insert into auth.users(id) values ('aaaaaaaa-0000-0000-0000-000000000008');
    insert into public.folders(id,user_id,name) values
      ('bbbbbbbb-0000-0000-0000-000000000008','aaaaaaaa-0000-0000-0000-000000000008','ui overlap');
    insert into public.vocabulary(user_id,folder_id,kanji,kana,romaji,meaning) values
      ('aaaaaaaa-0000-0000-0000-000000000008','bbbbbbbb-0000-0000-0000-000000000008','井囲','かな','test','test');
    set role authenticated;
    select set_config('request.jwt.claim.sub','aaaaaaaa-0000-0000-0000-000000000008',false);
    select public.recalculate_user_kanji_and_radical_stats();
    reset role;
  `);
  const beforeUiOverlap = (await db.query(`select
    (select jsonb_agg(t order by kanji_id, occurrence_id) from public.kanji_component_occurrences t) as occurrences,
    (select jsonb_agg(t order by kanji_id, radical_id, component_form) from public.kanji_radical_stat_components t) as statistic_components,
    (select jsonb_agg(t order by kanji_id, radical_id, component_form) from public.kanji_components t) as components,
    public.get_user_kanji_snapshot() as snapshot`)).rows[0];
  await db.exec(await readFile('supabase/migrations/202609180001_kanji_ui_overlap_v3.sql', 'utf8'));
  const afterUiOverlap = (await db.query(`select
    (select jsonb_agg(t order by kanji_id, occurrence_id) from public.kanji_component_occurrences t) as occurrences,
    (select jsonb_agg(t order by kanji_id, radical_id, component_form) from public.kanji_radical_stat_components t) as statistic_components,
    (select jsonb_agg(t order by kanji_id, radical_id, component_form) from public.kanji_components t) as components,
    public.get_user_kanji_snapshot() as snapshot`)).rows[0];
  if (JSON.stringify(beforeUiOverlap.occurrences) !== JSON.stringify(afterUiOverlap.occurrences) ||
      JSON.stringify(beforeUiOverlap.statistic_components) !== JSON.stringify(afterUiOverlap.statistic_components) ||
      JSON.stringify(beforeUiOverlap.snapshot) !== JSON.stringify(afterUiOverlap.snapshot)) {
    throw new Error('UI overlap migration changed strict occurrences, statistics or user snapshots');
  }
  if (JSON.stringify(beforeUiOverlap.components) === JSON.stringify(afterUiOverlap.components)) {
    throw new Error('UI overlap migration did not rebuild related-Kanji components');
  }
  await db.exec(await readFile('supabase/tests/fixtures/kanji_ui_overlap_assertions.sql', 'utf8'));
  await db.exec("delete from auth.users where id='aaaaaaaa-0000-0000-0000-000000000008'; select set_config('request.jwt.claim.sub','',false);");
  console.log('PASS: UI overlap changes only trees and related-Kanji components.');
  // Supabase supplies table privileges by default; replicate that for old tables.
  await db.exec(`grant select, insert, update, delete on public.folders, public.vocabulary, public.srs_progress to authenticated;`);
  const assertions = await readFile('supabase/tests/fixtures/kanji_assertions.sql', 'utf8');
  await db.exec(assertions);
  console.log('PASS: base Kanji assertions.');
  await db.exec(await readFile('supabase/tests/fixtures/kanji_occurrences_assertions.sql', 'utf8'));
  console.log('PASS: component occurrence assertions.');
  await db.exec(await readFile('supabase/tests/fixtures/kanji_radical_forms_assertions.sql', 'utf8'));
  console.log('PASS: radical form assertions.');
  console.log('PASS: Kanji schema, counts, idempotency, cleanup, roles/RLS, Unicode, snapshot >1000 rows, atomic rollback.');

  if (process.argv.includes('--assertions-only')) {
    console.log('PASS: v3 occurrences and v4 nested manual statistics.');
  } else {
  const timings = [];
  for (const size of [1000, 10000, 50000]) {
    await db.exec(`
      insert into auth.users(id) values ('10000000-0000-0000-0000-000000000001') on conflict do nothing;
      insert into public.folders(id,user_id,name) values ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','benchmark') on conflict (id) do nothing;
      delete from public.vocabulary where user_id='10000000-0000-0000-0000-000000000001';
      insert into public.vocabulary(user_id,folder_id,kanji,kana,romaji,meaning)
      select '10000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','日本語学習先生休森𠮷','かな','test','benchmark' from generate_series(1,${size});
      set role authenticated;
      select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',false);
    `);
    const samples = [];
    for (let repeat = 0; repeat < 3; repeat++) {
      const start = performance.now();
      await db.exec('select public.recalculate_user_kanji_and_radical_stats()');
      samples.push(Math.round((performance.now()-start)*10)/10);
    }
    await db.exec('reset role');
    timings.push({vocabulary_rows: size, elapsed_ms: samples});
    console.log(`Benchmark ${size}: ${samples.join(', ')} ms`);
  }
  await writeFile('tool/kanji/benchmark_report.json', JSON.stringify({
    engine: 'PGlite 0.3.14 (local PostgreSQL WASM, NOT Supabase production latency)',
    node: process.version, measurements: timings,
  }, null, 2) + '\n');
  }
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally { await db.close(); }
