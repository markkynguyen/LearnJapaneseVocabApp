begin;
do $$ begin
  assert (select count(*) from public.kanji_decompositions where structure_version=3) = 2136;
  assert (select array_agg(child->>'display_form' order by ord)
    from public.kanji_decompositions,
      jsonb_array_elements(tree->'children') with ordinality c(child,ord)
    where kanji_id=ascii('井')) = array['二','廾'];
  assert (select (tree->'children'->0->'stroke_ids') ? 'kvg:04e95-s2'
    and (tree->'children'->1->'stroke_ids') ? 'kvg:04e95-s2'
    from public.kanji_decompositions where kanji_id=ascii('井'));
  assert exists(select 1 from public.kanji_components
    where kanji_id=ascii('井') and radical_id=7 and component_form='二');
  assert exists(select 1 from public.kanji_components
    where kanji_id=ascii('井') and radical_id=55 and component_form='廾');
end $$;
rollback;
