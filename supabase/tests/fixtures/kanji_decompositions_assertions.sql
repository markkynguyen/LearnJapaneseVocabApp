begin;
do $$
declare count_rows integer;
begin
  select count(*) into count_rows from public.kanji_decompositions;
  assert count_rows = 2136, 'Expected 2136 complete root documents';
  assert (select tree #>> '{children,0,display_form}' from public.kanji_decompositions where kanji_id=24819) = '相', '想 starts with 相';
  assert (select tree #>> '{children,0,children,0,display_form}' from public.kanji_decompositions where kanji_id=24819) = '木', '相 contains 木';
  assert (select tree #>> '{children,1,display_form}' from public.kanji_decompositions where kanji_id=26862) = '林', '森 retains 林';
  assert not has_table_privilege('anon','public.kanji_decompositions','SELECT'), 'anon cannot read';
  assert not has_table_privilege('authenticated','public.kanji_decompositions','INSERT'), 'client cannot insert';
  assert not has_table_privilege('authenticated','public.kanji_decompositions','UPDATE'), 'client cannot update';
  assert not has_table_privilege('authenticated','public.kanji_decompositions','DELETE'), 'client cannot delete';
end $$;
set local role authenticated;
do $$ begin
  assert (select count(*) from public.kanji_decompositions) = 2136, 'authenticated can read catalog';
end $$;
reset role;
rollback;
