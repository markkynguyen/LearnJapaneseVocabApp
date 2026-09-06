begin;
create table public.kanji_component_occurrences (
  kanji_id integer not null references public.kanji(id) on delete cascade,
  occurrence_id text not null,
  sort_order smallint not null check (sort_order >= 0),
  display_form text,
  source_element text,
  source_original text,
  radical_id smallint references public.radicals(id),
  source_group_ids text[] not null,
  stroke_ids text[] not null check (cardinality(stroke_ids) > 0),
  component_version smallint not null check (component_version = 2),
  kanjivg_commit text not null check (kanjivg_commit ~ '^[a-f0-9]{40}$'),
  primary key (kanji_id, occurrence_id),
  unique (kanji_id, sort_order),
  check (radical_id is null or char_length(display_form) = 1)
);
create index kanji_occurrences_radical_idx on public.kanji_component_occurrences(radical_id, kanji_id);
alter table public.kanji_component_occurrences enable row level security;
create policy kanji_occurrences_read on public.kanji_component_occurrences for select to authenticated using (true);
revoke all on public.kanji_component_occurrences from anon, authenticated;
grant select on public.kanji_component_occurrences to authenticated;
-- Existing snapshots retain version 1 and their original counts/timestamps.
alter table public.user_kanji_stats_overview add column component_version smallint not null default 1 check (component_version > 0);
commit;
