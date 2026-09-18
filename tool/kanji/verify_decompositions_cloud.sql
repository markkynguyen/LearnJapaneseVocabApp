-- Read-only deployment verification. Never calls the statistics RPC.
with recursive nodes as (
  select kanji_id, tree as node from public.kanji_decompositions
  union all
  select n.kanji_id, c.value from nodes n,
       lateral jsonb_array_elements(n.node->'children') c
)
select (select count(*) from public.kanji_decompositions) as tree_count,
  (select count(distinct kanjivg_commit) from public.kanji_decompositions) as source_versions,
  (select jsonb_agg(example) from (
    select k.character, d.tree #>> '{children,0,display_form}' as first_component,
           d.tree #>> '{children,1,display_form}' as second_component
    from public.kanji_decompositions d join public.kanji k on k.id=d.kanji_id
    where k.character in ('想','謝','森','語','憾','機') order by k.character
  ) example) as samples,
  count(*) as node_count,
  count(*) filter (where jsonb_array_length(node->'children') > 0 and (
    exists (select 1 from jsonb_array_elements_text(node->'stroke_ids') parent_stroke
      where not exists (select 1 from jsonb_array_elements(node->'children') child,
        lateral jsonb_array_elements_text(child.value->'stroke_ids') child_stroke
        where child_stroke.value = parent_stroke.value))
    or exists (select 1 from jsonb_array_elements(node->'children') child,
      lateral jsonb_array_elements_text(child.value->'stroke_ids') child_stroke
      where not (node->'stroke_ids' ? child_stroke.value))
  )) as invalid_coverage,
  count(*) filter (where jsonb_array_length(node->'children') > 0 and exists (
    select 1 from jsonb_array_elements(node->'children') with ordinality left_child(value, position),
      jsonb_array_elements(node->'children') with ordinality right_child(value, position),
      lateral jsonb_array_elements_text(left_child.value->'stroke_ids') left_stroke,
      lateral jsonb_array_elements_text(right_child.value->'stroke_ids') right_stroke
    where left_child.position < right_child.position and left_stroke.value = right_stroke.value
  )) as nodes_with_shared_strokes,
       has_table_privilege('authenticated','public.kanji_decompositions','SELECT') as authenticated_read,
       has_table_privilege('authenticated','public.kanji_decompositions','UPDATE') as authenticated_write,
       has_table_privilege('anon','public.kanji_decompositions','SELECT') as anon_read
from nodes;
