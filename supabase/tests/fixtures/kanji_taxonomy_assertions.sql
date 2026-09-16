begin;
create temporary table taxonomy_nodes as
with recursive nodes as (
  select kanji_id, tree as node from public.kanji_decompositions
  union all
  select kanji_id, child from nodes cross join lateral jsonb_array_elements(node->'children') child
) select * from nodes;
do $$ begin
  assert (select count(*) from public.kanji_decompositions) = 2136;
  assert not exists (select 1 from public.kanji_decompositions where structure_version <> 2);
  assert not exists (select 1 from public.kanji_component_occurrences where component_version <> 3);
  assert not exists (select 1 from taxonomy_nodes where node->>'kind' not in ('radical','kanji','supplementary'));
  assert not exists (select 1 from taxonomy_nodes n where node->>'kind' = 'kanji'
    and not exists(select 1 from public.kanji k where k.character = n.node->>'display_form'));
  assert not exists (select 1 from taxonomy_nodes n where node->>'kind' = 'radical'
    and (jsonb_array_length(node->'children') <> 0 or not exists (
      select 1 from public.radicals r where r.id = (node->>'radical_id')::integer)));
  assert not exists (select 1 from taxonomy_nodes where node->>'kind' = 'supplementary'
    and jsonb_array_length(node->'children') <> 0);
  assert (select array_agg(n->>'display_form' order by ord) from public.kanji_decompositions,
    jsonb_array_elements(tree->'children') with ordinality c(n,ord) where kanji_id=ascii('座')) = array['广','人','人','土'];
  assert (select tree->'children'->0->>'display_form' from public.kanji_decompositions where kanji_id=ascii('孝')) = '耂';
  assert (select tree->'children'->0->>'radical_name' from public.kanji_decompositions where kanji_id=ascii('孝')) = 'Lão';
  assert (select tree->'children'->0->>'radical_id' from public.kanji_decompositions where kanji_id=ascii('孝')) = '125';
  assert not exists (
    (select kanji_id, node->>'id' from taxonomy_nodes where jsonb_array_length(node->'children')=0)
    except (select kanji_id, occurrence_id from public.kanji_component_occurrences));
  assert not exists (
    (select kanji_id, occurrence_id from public.kanji_component_occurrences)
    except (select kanji_id, node->>'id' from taxonomy_nodes where jsonb_array_length(node->'children')=0));
  assert not exists (select 1 from public.kanji_component_occurrences c
    join taxonomy_nodes n on n.kanji_id=c.kanji_id and n.node->>'id'=c.occurrence_id
    where to_jsonb(c.stroke_ids) <> n.node->'stroke_ids' or c.kind <> n.node->>'kind');
  assert not exists (
    (select kanji_id,radical_id,display_form from public.kanji_component_occurrences where radical_id is not null)
    except (select kanji_id,radical_id,component_form from public.kanji_components));
  assert (select occurrence_count from public.kanji_radical_stat_components
    where kanji_id=ascii('員') and radical_id=30 and component_form='口')=1;
  assert (select occurrence_count from public.kanji_radical_stat_components
    where kanji_id=ascii('員') and radical_id=154 and component_form='貝')=1;
  assert (select occurrence_count from public.kanji_radical_stat_components
    where kanji_id=ascii('員') and radical_id=109 and component_form='目')=1;
  assert (select occurrence_count from public.kanji_radical_stat_components
    where kanji_id=ascii('員') and radical_id=12 and component_form='八')=1;
  assert (select occurrence_count from public.kanji_radical_stat_components
    where kanji_id=ascii('森') and radical_id=75 and component_form='木')=3;
  assert (select occurrence_count from public.kanji_radical_stat_components
    where kanji_id=ascii('佳') and radical_id=32 and component_form='土')=2;
  assert not exists(select 1 from public.kanji_components
    where kanji_id=ascii('員') and component_form in ('目','八'));
  assert not has_table_privilege('authenticated','public.kanji_radical_stat_components','SELECT');
end $$;
insert into auth.users(id) values ('aaaaaaaa-0000-0000-0000-000000000009');
insert into public.folders(id,user_id,name) values
  ('bbbbbbbb-0000-0000-0000-000000000009','aaaaaaaa-0000-0000-0000-000000000009','taxonomy');
insert into public.vocabulary(user_id,folder_id,kanji,kana,romaji,meaning) values
  ('aaaaaaaa-0000-0000-0000-000000000009','bbbbbbbb-0000-0000-0000-000000000009','座座孝学員損佳森','かな','test','test');
set local role authenticated;
select set_config('request.jwt.claim.sub','aaaaaaaa-0000-0000-0000-000000000009',true);
select public.recalculate_user_kanji_and_radical_stats();
do $$ begin
  assert (select count from public.user_radical_stats where radical_id=9)=5, 'Each 人 position in 座 is counted';
  assert (select count from public.user_radical_stats where radical_id=42)=1, '⺍ counts as 小';
  assert (select component_version from public.user_kanji_stats_overview)=4;
  assert (select count from public.user_radical_stats where radical_id=30)=2, '員 and 損 each contribute 口';
  assert (select count from public.user_radical_stats where radical_id=154)=2, '員 and 損 each contribute 貝';
  assert (select count from public.user_radical_stats where radical_id=109)=2, '員 and 損 each contribute 目';
  assert (select count from public.user_radical_stats where radical_id=12)=2, '員 and 損 each contribute 八';
  assert (select count from public.user_radical_stats where radical_id=75)=3, '森 contributes three 木';
  assert (select count from public.user_radical_stats where radical_id=32)=5, 'Nested 土 positions are counted';
  assert (select count from jsonb_to_recordset(public.get_user_kanji_snapshot()->'radical_forms')
    as f(id integer, form text, count bigint) where id=109 and form='目')=2, 'Nested form count is exposed';
  assert (select count(*) from public.kanji_components where kanji_id=ascii('孝') and radical_id=125 and component_form='耂')=1;
end $$;
reset role;
rollback;
