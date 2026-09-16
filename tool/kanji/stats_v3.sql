create or replace function public.recalculate_user_kanji_and_radical_stats() returns void
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  snapshot jsonb;
  scanned bigint;
  calculated timestamptz;
begin
  if uid is null then raise exception 'authentication required'; end if;
  -- Hai thiết bị của cùng người dùng không thể ghi đè xen kẽ các bảng thống kê.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('kanji:' || uid::text, 0));
  calculated := clock_timestamp();
  -- Chụp cả số từ và số ký tự trong cùng một SQL snapshot trước khi ghi kết quả.
  with vocab as materialized (
    select v.kanji from public.vocabulary v
    where v.user_id = uid
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
  select uid, c.radical_id, sum(s.count), calculated
  from public.user_kanji_stats s
  join (select distinct kanji_id, radical_id from public.kanji_components) c on c.kanji_id = s.kanji_id
  where s.user_id = uid group by c.radical_id;
  insert into public.user_kanji_stats_overview(user_id, last_calculated_at,
    total_kanji_count, total_radical_count, total_vocab_scanned, unsupported_kanji_count, component_version, updated_at)
  values (uid, calculated,
    (select count(*) from public.user_kanji_stats where user_id = uid),
    (select count(*) from public.user_radical_stats where user_id = uid), scanned,
    (select count(*) from jsonb_to_recordset(snapshot) c(character text, count bigint)
      where not exists (select 1 from public.kanji k where k.character = c.character)), 3, calculated)
  on conflict (user_id) do update set last_calculated_at = excluded.last_calculated_at,
    total_kanji_count = excluded.total_kanji_count, total_radical_count = excluded.total_radical_count,
    total_vocab_scanned = excluded.total_vocab_scanned, unsupported_kanji_count = excluded.unsupported_kanji_count,
    component_version = excluded.component_version, updated_at = excluded.updated_at;
end;
$$;
