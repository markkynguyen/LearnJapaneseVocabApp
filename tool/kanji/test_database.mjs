// Local PostgreSQL/WASM harness. Does not connect to or modify Supabase cloud.
// Bootstrap dependency once: python tool/kanji/prepare_test_db.py
import { PGlite } from './.cache/package/dist/index.js';
import { readFile, readdir, writeFile } from 'node:fs/promises';
import { performance } from 'node:perf_hooks';

const db = new PGlite();
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
    let sql = await readFile(`supabase/migrations/${file}`, 'utf8');
    // PGlite ships gen_random_uuid in core, but does not bundle pgcrypto.
    sql = sql.replace('create extension if not exists pgcrypto;', '');
    await db.exec(sql);
    console.log(`Applied ${file}`);
  }
  // Supabase supplies table privileges by default; replicate that for old tables.
  await db.exec(`grant select, insert, update, delete on public.folders, public.vocabulary, public.srs_progress to authenticated;`);
  const assertions = await readFile('supabase/tests/fixtures/kanji_assertions.sql', 'utf8');
  await db.exec(assertions);
  console.log('PASS: Kanji schema, counts, idempotency, cleanup, roles/RLS, Unicode, snapshot >1000 rows, atomic rollback.');

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
} catch (error) {
  console.error(error.message);
  process.exitCode = 1;
} finally { await db.close(); }
