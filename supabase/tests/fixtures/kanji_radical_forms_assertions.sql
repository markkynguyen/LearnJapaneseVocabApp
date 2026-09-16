begin;

insert into auth.users(id)
values ('aaaaaaaa-0000-0000-0000-000000000005');
insert into public.folders(id,user_id,name)
values (
  'bbbbbbbb-0000-0000-0000-000000000005',
  'aaaaaaaa-0000-0000-0000-000000000005',
  'radical form test'
);
insert into public.vocabulary(user_id,folder_id,kanji,kana,romaji,meaning)
values (
  'aaaaaaaa-0000-0000-0000-000000000005',
  'bbbbbbbb-0000-0000-0000-000000000005',
  '休休企森森',
  'かな',
  'test',
  'test'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'aaaaaaaa-0000-0000-0000-000000000005',
  true
);
select public.recalculate_user_kanji_and_radical_stats();

do $$
declare
  snapshot jsonb := public.get_user_kanji_snapshot();
begin
  assert (snapshot->'overview'->>'total_radical_count')::integer =
    (select count(*) from public.user_radical_stats where user_id = auth.uid()),
    'family total changed';
  assert (
    select array_agg(form order by form_order)
    from jsonb_to_recordset(snapshot->'radical_forms')
      as f(id integer, form text, form_order integer)
    where id = 9
  ) = array['人','亻'], 'zero-count forms should be omitted: ' || coalesce((
    select array_agg(form order by form_order)::text
    from jsonb_to_recordset(snapshot->'radical_forms')
      as f(id integer, form text, form_order integer)
    where id = 9
  ), 'null');
  assert (
    select array_agg(count order by form_order)
    from jsonb_to_recordset(snapshot->'radical_forms')
      as f(id integer, count bigint, form_order integer)
    where id = 9
  ) = array[1,2]::bigint[], 'human form counts are wrong';
  assert not exists (
    select 1
    from jsonb_to_recordset(snapshot->'radical_forms')
      as f(id integer, count bigint)
    where count <= 0
  ), 'zero-count forms should not be included';
  assert (
    select coalesce(bool_and(count >= next_count), true)
    from (
      select
        (item->>'count')::bigint as count,
        lead((item->>'count')::bigint) over (order by ordinality) as next_count
      from jsonb_array_elements(snapshot->'radical_forms') with ordinality
        as entries(item, ordinality)
    ) ordered
    where next_count is not null
  ), 'forms are not globally sorted by count';
  assert not exists (
    select 1
    from jsonb_to_recordset(snapshot->'radical_forms')
      as f(id integer, family_count bigint)
    where id = 9 and family_count <> 3
  ), 'family count differs between forms';
  assert (
    select count
    from jsonb_to_recordset(snapshot->'radical_forms')
      as f(id integer, form text, count bigint)
    where id = 75 and form = '木'
  ) = 8, '休 and each 森 contribute all 木 positions';
end $$;

reset role;
rollback;
