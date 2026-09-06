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
  ) = array['人','亻','𠆢','入'], 'family forms or order are wrong: ' || coalesce((
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
  ) = array[1,2,0,0]::bigint[], 'human form counts are wrong';
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
  ) = 4, '森 contributes one 木 per Kanji occurrence';
end $$;

reset role;
rollback;
