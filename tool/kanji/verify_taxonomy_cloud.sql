-- Read only. Never calls the user's statistics update RPC.
with recursive nodes as (
  select kanji_id,tree as node from public.kanji_decompositions
  union all
  select kanji_id,c from nodes cross join lateral jsonb_array_elements(node->'children') c
)
select
  (select count(*) from public.kanji) as joyo_count,
  (select count(*) from public.radicals) as radical_count,
  (select count(*) from public.kanji_decompositions where structure_version=3) as trees_v3,
  (select count(*) from public.kanji_component_occurrences where component_version=3) as occurrences_v3,
  (select count(*) from public.kanji_radical_stat_components) as statistic_components_v4,
  (select count(*) from public.kanji_components) as relations,
  (select count(*) from public.user_kanji_stats_overview) as statistics_snapshots,
  count(*) as nodes,
  count(*) filter(where node->>'kind'='partial') as partial_nodes,
  count(*) filter(where node->>'kind'='kanji' and not exists(
    select 1 from public.kanji k where k.character=node->>'display_form')) as non_joyo_kanji,
  count(*) filter(where jsonb_array_length(node->'children')>0 and (
    exists (select 1 from jsonb_array_elements_text(node->'stroke_ids') parent_stroke
      where not exists (select 1 from jsonb_array_elements(node->'children') child,
        lateral jsonb_array_elements_text(child->'stroke_ids') child_stroke
        where child_stroke = parent_stroke))
    or exists (select 1 from jsonb_array_elements(node->'children') child,
      lateral jsonb_array_elements_text(child->'stroke_ids') child_stroke
      where not (node->'stroke_ids' ? child_stroke))
  )) as invalid_coverage,
  count(*) filter(where jsonb_array_length(node->'children')>0 and exists (
    select 1 from jsonb_array_elements(node->'children') with ordinality left_child(value, position),
      jsonb_array_elements(node->'children') with ordinality right_child(value, position),
      lateral jsonb_array_elements_text(left_child.value->'stroke_ids') left_stroke,
      lateral jsonb_array_elements_text(right_child.value->'stroke_ids') right_stroke
    where left_child.position < right_child.position and left_stroke = right_stroke
  )) as nodes_with_shared_strokes,
  has_table_privilege('authenticated','public.kanji_decompositions','SELECT') as authenticated_read,
  has_table_privilege('authenticated','public.kanji_decompositions','UPDATE') as authenticated_write,
  has_table_privilege('anon','public.kanji_decompositions','SELECT') as anon_read
from nodes;
