begin;
create table public.kanji_decompositions (
  kanji_id integer primary key references public.kanji(id) on delete cascade,
  structure_version smallint not null check (structure_version = 1),
  kanjivg_commit text not null check (kanjivg_commit ~ '^[a-f0-9]{40}$'),
  tree jsonb not null check (
    jsonb_typeof(tree) = 'object' and
    tree ?& array['id','kind','stroke_ids','children'] and
    jsonb_typeof(tree->'children') = 'array' and
    jsonb_typeof(tree->'stroke_ids') = 'array' and
    jsonb_array_length(tree->'stroke_ids') > 0
  )
);
alter table public.kanji_decompositions enable row level security;
create policy kanji_decompositions_read on public.kanji_decompositions
  for select to authenticated using (true);
revoke all on public.kanji_decompositions from anon, authenticated;
grant select on public.kanji_decompositions to authenticated;
commit;
