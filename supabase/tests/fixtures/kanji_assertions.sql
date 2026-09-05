-- Transactional assertions shared by pgTAP and the offline PGlite harness.
begin;
insert into auth.users(id) values
  ('aaaaaaaa-0000-0000-0000-000000000001'),
  ('aaaaaaaa-0000-0000-0000-000000000002');
insert into public.folders(id,user_id,name,is_study_paused) values
  ('bbbbbbbb-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','test',true),
  ('bbbbbbbb-0000-0000-0000-000000000002','aaaaaaaa-0000-0000-0000-000000000002','other',false);
insert into public.vocabulary(user_id,folder_id,kanji,kana,romaji,meaning) values
  ('aaaaaaaa-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','先生先生休森𠮷𠮷𠮟々🙂abcあ','かな','kana','test'),
  ('aaaaaaaa-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001',null,'かな','kana','test'),
  ('aaaaaaaa-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','  ','かな','kana','test'),
  ('aaaaaaaa-0000-0000-0000-000000000002','bbbbbbbb-0000-0000-0000-000000000002','日日日','かな','kana','other');
do $$ begin
  assert (select count(*) from public.kanji)=2136, 'Joyo coverage';
  assert (select count(*) from public.radicals)=214, 'Kangxi coverage';
  assert not exists(select 1 from public.kanji where meaning_vi is null or han_viet is null), 'Vietnamese coverage';
  assert not exists(select 1 from public.kanji k where not exists(select 1 from public.kanji_components c where c.kanji_id=k.id)), 'Components coverage';
  assert not has_table_privilege('authenticated','public.kanji','INSERT'), 'Catalog write denied';
  assert not has_table_privilege('authenticated','public.user_kanji_stats','UPDATE'), 'Stats direct update denied';
  assert not has_function_privilege('anon','public.recalculate_user_kanji_and_radical_stats()','EXECUTE'), 'Anon RPC denied';
  assert public.is_kanji_codepoint(ascii('𠮷')) and public.is_kanji_codepoint(ascii('𠮟')), 'Supplementary CJK';
  assert public.is_kanji_codepoint(205744), 'Unicode 17 extension J';
  assert not public.is_kanji_codepoint(ascii('々')) and not public.is_kanji_codepoint(ascii('🙂')), 'Non CJK excluded';
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub','aaaaaaaa-0000-0000-0000-000000000001',true);
select public.recalculate_user_kanji_and_radical_stats();
select public.recalculate_user_kanji_and_radical_stats();
do $$ begin
  assert (select count from public.user_kanji_stats where kanji_id=ascii('先'))=2, 'Repeated characters';
  assert (select total_kanji_count from public.user_kanji_stats_overview)=5, 'Distinct supported Kanji';
  assert (select unsupported_kanji_count from public.user_kanji_stats_overview)=1, 'Distinct unknown Kanji';
  assert (select total_vocab_scanned from public.user_kanji_stats_overview)=3, 'All library rows scanned, including empty Kanji fields';
  assert (select count from public.user_radical_stats where radical_id=75)=2, 'Wood in 休 and 森 counted once per Kanji occurrence';
  assert (select count(*) from public.user_kanji_stats)=5, 'No duplicate stats after repeated RPC';
  assert jsonb_array_length(public.get_user_kanji_snapshot()->'kanji')=5, 'Snapshot count';
end $$;
select set_config('request.jwt.claim.sub','aaaaaaaa-0000-0000-0000-000000000002',true);
do $$ begin
  assert (select count(*) from public.user_kanji_stats)=0, 'Other account stats hidden by RLS';
  assert public.get_user_kanji_snapshot()->'overview'='null'::jsonb, 'No implicit recalc';
end $$;
select public.recalculate_user_kanji_and_radical_stats();
do $$ begin
  assert (select count from public.user_kanji_stats where kanji_id=ascii('日'))=3, 'Other account owns its own stats';
end $$;
select set_config('request.jwt.claim.sub','aaaaaaaa-0000-0000-0000-000000000001',true);
delete from public.vocabulary where user_id=auth.uid();
do $$ begin
  assert (select count(*) from public.user_kanji_stats)=5, 'Edits do not automatically change stats';
end $$;
select public.recalculate_user_kanji_and_radical_stats();
do $$ begin
  assert (select count(*) from public.user_kanji_stats)=0, 'Deleted Kanji removed';
  assert (select count(*) from public.user_radical_stats)=0, 'Deleted radicals removed';
  assert (select total_kanji_count+total_radical_count+unsupported_kanji_count+total_vocab_scanned from public.user_kanji_stats_overview)=0, 'Empty overview';
end $$;
insert into public.vocabulary(user_id,folder_id,kanji,kana,romaji,meaning)
select auth.uid(),'bbbbbbbb-0000-0000-0000-000000000001',string_agg(character,''),'かな','kana','full catalog' from public.kanji;
select public.recalculate_user_kanji_and_radical_stats();
do $$ begin
  assert jsonb_array_length(public.get_user_kanji_snapshot()->'kanji')=2136, 'Snapshot not truncated at PostgREST default 1000';
end $$;
reset role;
-- Force a late error. PostgreSQL must roll back all earlier stats deletions.
create function pg_temp.fail_stats_update() returns trigger language plpgsql as $$ begin raise exception 'intentional test failure'; end $$;
create trigger test_fail_stats before update on public.user_kanji_stats_overview for each row execute function pg_temp.fail_stats_update();
set local role authenticated;
delete from public.vocabulary where user_id=auth.uid();
do $$ begin
  begin
    perform public.recalculate_user_kanji_and_radical_stats();
    raise exception 'RPC should have failed';
  exception when raise_exception then
    if sqlerrm <> 'intentional test failure' then raise; end if;
  end;
  assert (select count(*) from public.user_kanji_stats)=2136, 'Failed recalc preserves old snapshot atomically';
end $$;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
  begin
    perform public.recalculate_user_kanji_and_radical_stats();
    raise exception 'null uid was allowed';
  exception when raise_exception then
    if sqlerrm <> 'authentication required' then raise; end if;
  end;
end $$;
reset role;
rollback;
