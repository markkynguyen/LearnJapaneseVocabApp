-- Generated taxonomy v4. Sources/licences: assets/kanji/ATTRIBUTION.md.
-- Feature-only rebuild. No auth, vocabulary, folders, SRS or settings writes.
begin;
create table if not exists public.kanji_radical_stat_components (
  kanji_id integer not null references public.kanji(id) on delete cascade,
  radical_id smallint not null references public.radicals(id),
  component_form text not null check (char_length(component_form) = 1),
  occurrence_count smallint not null check (occurrence_count > 0),
  sort_order smallint not null check (sort_order >= 0),
  primary key (kanji_id, radical_id, component_form)
);
create index if not exists kanji_radical_stat_components_radical_idx
  on public.kanji_radical_stat_components(radical_id, kanji_id);
alter table public.kanji_radical_stat_components enable row level security;
revoke all on public.kanji_radical_stat_components from anon, authenticated;
-- Fail closed if an unreviewed feature starts referencing the rebuilt tables.
do $$
declare
  feature_tables oid[] := array[
    'public.radicals'::regclass, 'public.kanji'::regclass,
    'public.kanji_components'::regclass, 'public.kanji_decompositions'::regclass,
    'public.kanji_component_occurrences'::regclass, 'public.user_kanji_stats'::regclass,
    'public.user_radical_stats'::regclass, 'public.user_kanji_stats_overview'::regclass,
    'public.kanji_radical_stat_components'::regclass];
begin
  if exists(select 1 from pg_catalog.pg_constraint where contype='f'
      and confrelid=any(feature_tables) and not conrelid=any(feature_tables)) then
    raise exception 'Unreviewed table references Kanji data; aborting feature rebuild';
  end if;
end $$;
lock table public.radicals, public.kanji, public.kanji_components,
  public.kanji_decompositions, public.kanji_component_occurrences,
  public.user_kanji_stats, public.user_radical_stats,
  public.user_kanji_stats_overview,
  public.kanji_radical_stat_components in access exclusive mode;

delete from public.user_kanji_stats_overview;
delete from public.user_radical_stats;
delete from public.user_kanji_stats;
delete from public.kanji_radical_stat_components;
delete from public.kanji_components;
delete from public.kanji_component_occurrences;
delete from public.kanji_decompositions;
delete from public.kanji;
delete from public.radicals;

-- Statistics stay empty until the existing manual update action is invoked.
