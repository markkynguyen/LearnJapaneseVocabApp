create or replace function public.recalculate_user_kanji_and_radical_stats() returns void
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  snapshot jsonb;
  scanned bigint;
  calculated timestamptz;
begin
  if uid is null then raise exception 'authentication required'; end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('kanji:' || uid::text, 0));
  calculated := clock_timestamp();
  with vocab as materialized (
    select v.kanji from public.vocabulary v where v.user_id = uid
  ), chars as (
    select ch, count(*) as count
    from vocab v cross join lateral regexp_split_to_table(v.kanji, '') ch
    where public.is_kanji_codepoint(ascii(ch)) group by ch
  )
  select (select count(*) from vocab),
    coalesce((select jsonb_agg(jsonb_build_object('character', ch, 'count', count)) from chars), '[]'::jsonb)
  into scanned, snapshot;

  delete from public.user_radical_stats where user_id = uid;
  delete from public.user_kanji_stats where user_id = uid;
  insert into public.user_kanji_stats(user_id, kanji_id, count, updated_at)
  select uid, k.id, c.count, calculated
  from jsonb_to_recordset(snapshot) c(character text, count bigint)
  join public.kanji k on k.character = c.character;
  insert into public.user_radical_stats(user_id, radical_id, count, updated_at)
  select uid, c.radical_id, sum(s.count * c.occurrence_count), calculated
  from public.user_kanji_stats s
  join public.kanji_radical_stat_components c on c.kanji_id = s.kanji_id
  where s.user_id = uid group by c.radical_id;
  insert into public.user_kanji_stats_overview(user_id, last_calculated_at,
    total_kanji_count, total_radical_count, total_vocab_scanned, unsupported_kanji_count, component_version, updated_at)
  values (uid, calculated,
    (select count(*) from public.user_kanji_stats where user_id = uid),
    (select count(*) from public.user_radical_stats where user_id = uid), scanned,
    (select count(*) from jsonb_to_recordset(snapshot) c(character text, count bigint)
      where not exists (select 1 from public.kanji k where k.character = c.character)), 4, calculated)
  on conflict (user_id) do update set last_calculated_at = excluded.last_calculated_at,
    total_kanji_count = excluded.total_kanji_count, total_radical_count = excluded.total_radical_count,
    total_vocab_scanned = excluded.total_vocab_scanned, unsupported_kanji_count = excluded.unsupported_kanji_count,
    component_version = excluded.component_version, updated_at = excluded.updated_at;
end;
$$;

create or replace function public.get_user_kanji_snapshot() returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object(
    'overview', (select to_jsonb(o) from public.user_kanji_stats_overview o where o.user_id = auth.uid()),
    'kanji', coalesce((select jsonb_agg(to_jsonb(k) || jsonb_build_object('count', s.count) order by s.count desc, k.id)
      from public.user_kanji_stats s join public.kanji k on k.id = s.kanji_id where s.user_id = auth.uid()), '[]'::jsonb),
    'radicals', coalesce((select jsonb_agg(to_jsonb(r) || jsonb_build_object('count', s.count) order by s.count desc, r.id)
      from public.user_radical_stats s join public.radicals r on r.id = s.radical_id where s.user_id = auth.uid()), '[]'::jsonb),
    'radical_forms', coalesce((
      with form_counts as (
        select c.radical_id, c.component_form, sum(s.count * c.occurrence_count) as count
        from public.user_kanji_stats s
        join public.kanji_radical_stat_components c on c.kanji_id = s.kanji_id
        where s.user_id = auth.uid()
        group by c.radical_id, c.component_form
      )
      select jsonb_agg(
        to_jsonb(r) || jsonb_build_object(
          'form', f.form,
          'count', fc.count,
          'family_count', family.count,
          'is_original', f.form_order = 0,
          'form_order', f.form_order
        ) order by fc.count desc, r.id, f.form_order
      )
      from public.user_radical_stats family
      join public.radicals r on r.id = family.radical_id
      cross join lateral (
        select r.character as form, 0::bigint as form_order
        union all
        select variant, ordinal from unnest(r.variants) with ordinality as variants(variant, ordinal)
      ) f
      join form_counts fc on fc.radical_id = r.id and fc.component_form = f.form
      where family.user_id = auth.uid()
    ), '[]'::jsonb)
  );
$$;
