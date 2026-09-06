begin;
do $$ begin
  assert (select count(distinct kanji_id) from public.kanji_component_occurrences)=2136;
  assert (select array_agg(display_form order by sort_order) from public.kanji_component_occurrences where kanji_id=ascii('機'))=array['木','幺','幺','戈','人'];
  assert (select array_agg(display_form order by sort_order) from public.kanji_component_occurrences where kanji_id=ascii('学'))=array['⺍','冖','子'];
  assert (select cardinality(stroke_ids) from public.kanji_component_occurrences where kanji_id=ascii('国') and display_form='囗')=3;
  assert not exists(select 1 from public.kanji_component_occurrences where display_form='⺍' and radical_id is not null);
  assert not exists(select 1 from public.kanji_components where kanji_id=ascii('機') and component_form in ('弋','丶'));
  assert not has_table_privilege('authenticated','public.kanji_component_occurrences','INSERT');
end $$;
insert into auth.users(id) values ('aaaaaaaa-0000-0000-0000-000000000003');
insert into public.folders(id,user_id,name) values ('bbbbbbbb-0000-0000-0000-000000000003','aaaaaaaa-0000-0000-0000-000000000003','v2 test');
insert into public.vocabulary(user_id,folder_id,kanji,kana,romaji,meaning) values ('aaaaaaaa-0000-0000-0000-000000000003','bbbbbbbb-0000-0000-0000-000000000003','機機森学','かな','test','test');
insert into public.user_kanji_stats_overview(user_id,last_calculated_at,total_kanji_count,total_radical_count,total_vocab_scanned,unsupported_kanji_count) values ('aaaaaaaa-0000-0000-0000-000000000003','2020-01-01',99,99,99,0);
set local role authenticated;
select set_config('request.jwt.claim.sub','aaaaaaaa-0000-0000-0000-000000000003',true);
do $$ begin
  assert (public.get_user_kanji_snapshot()->'overview'->>'component_version')::integer=1;
  assert (public.get_user_kanji_snapshot()->'overview'->>'total_kanji_count')::integer=99;
  assert (select count(*) from public.kanji_component_occurrences)>0, 'authenticated can read';
end $$;
select public.recalculate_user_kanji_and_radical_stats();
do $$ begin
  assert (select component_version from public.user_kanji_stats_overview)=2;
  assert (select count from public.user_radical_stats where radical_id=52)=2, 'two 機 contribute two 幺, not four';
  assert (select count from public.user_radical_stats where radical_id=75)=3, '機機森 contribute three 木, not five';
  assert (select count from public.user_radical_stats where radical_id=62)=2, 'two 機 contribute two 戈';
end $$;
reset role;
rollback;
