-- Read-only post-migration smoke check; does not read or recalculate user data.
with duplicate_strokes as (
  select kanji_id, stroke_id from public.kanji_component_occurrences,
    lateral unnest(stroke_ids) stroke_id
  group by kanji_id, stroke_id having count(*) <> 1
)
select
  (select count(*) from public.radicals) as radicals,
  (select count(*) from public.kanji) as kanji,
  (select count(distinct kanji_id) from public.kanji_component_occurrences) as covered_kanji,
  (select count(*) from public.kanji_component_occurrences) as occurrences,
  (select count(*) from duplicate_strokes) as overlapping_strokes,
  (select count(*) from public.kanji_components) as terminal_radical_relations,
  has_table_privilege('authenticated', 'public.kanji_component_occurrences', 'SELECT') as authenticated_read,
  has_table_privilege('anon', 'public.kanji_component_occurrences', 'SELECT') as anonymous_read,
  has_table_privilege('authenticated', 'public.kanji_component_occurrences', 'INSERT') as authenticated_write,
  has_function_privilege('anon', 'public.recalculate_user_kanji_and_radical_stats()', 'EXECUTE') as anonymous_recalculate,
  (select jsonb_object_agg(character, components) from (
    select k.character, jsonb_agg(jsonb_build_object('form', o.display_form, 'strokes', o.stroke_ids) order by o.sort_order) components
    from public.kanji_component_occurrences o join public.kanji k on k.id = o.kanji_id
    where k.character in ('機', '何', '学', '森', '国', '基') group by k.character
  ) samples) as samples;
