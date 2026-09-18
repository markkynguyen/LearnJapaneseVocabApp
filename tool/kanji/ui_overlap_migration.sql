-- Generated UI-overlap tree v3. This migration intentionally leaves the
-- strict occurrence/statistics projections and every user snapshot untouched.
begin;

lock table public.kanji_decompositions, public.kanji_components
  in access exclusive mode;

delete from public.kanji_components;
delete from public.kanji_decompositions;

alter table public.kanji_decompositions
  drop constraint kanji_decompositions_structure_version_check,
  add constraint kanji_decompositions_structure_version_check
    check (structure_version = 3);
