-- Regenerated from tool/kanji/build_components.py using pinned KanjiVG.
begin;

delete from public.kanji_component_occurrences
where kanji_id in (23041,24190,24863,25022,27231,27507,28187,28357,34065);

insert into public.kanji_component_occurrences (display_form,source_element,source_original,radical_id,source_group_ids,stroke_ids,occurrence_id,sort_order,kanji_id,component_version,kanjivg_commit) values
(null,null,null,null,array[]::text[],array['kvg:05a01-s1']::text[],'kvg:05a01-s1',0,23041,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('戈','戈',null,62,array['kvg:05a01-g3','kvg:05a01-g9']::text[],array['kvg:05a01-s2','kvg:05a01-s3','kvg:05a01-s7','kvg:05a01-s8','kvg:05a01-s9']::text[],'kvg:05a01-g3',1,23041,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('女','女',null,38,array['kvg:05a01-g7']::text[],array['kvg:05a01-s4','kvg:05a01-s5','kvg:05a01-s6']::text[],'kvg:05a01-g7',2,23041,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('幺','幺',null,52,array['kvg:05e7e-g1']::text[],array['kvg:05e7e-s1','kvg:05e7e-s2','kvg:05e7e-s3']::text[],'kvg:05e7e-g1',0,24190,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('幺','幺',null,52,array['kvg:05e7e-g2']::text[],array['kvg:05e7e-s4','kvg:05e7e-s5','kvg:05e7e-s6']::text[],'kvg:05e7e-g2',1,24190,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('戈','戈',null,62,array['kvg:05e7e-g4','kvg:05e7e-g10']::text[],array['kvg:05e7e-s7','kvg:05e7e-s10','kvg:05e7e-s11','kvg:05e7e-s12']::text[],'kvg:05e7e-g4',2,24190,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('人','人',null,9,array['kvg:05e7e-g7']::text[],array['kvg:05e7e-s8','kvg:05e7e-s9']::text[],'kvg:05e7e-g7',3,24190,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
(null,null,null,null,array[]::text[],array['kvg:0611f-s1']::text[],'kvg:0611f-s1',0,24863,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('戈','戈',null,62,array['kvg:0611f-g4','kvg:0611f-g10']::text[],array['kvg:0611f-s2','kvg:0611f-s7','kvg:0611f-s8','kvg:0611f-s9']::text[],'kvg:0611f-g4',1,24863,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('一','一',null,1,array['kvg:0611f-g7']::text[],array['kvg:0611f-s3']::text[],'kvg:0611f-g7',2,24863,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('口','口',null,30,array['kvg:0611f-g8']::text[],array['kvg:0611f-s4','kvg:0611f-s5','kvg:0611f-s6']::text[],'kvg:0611f-g8',3,24863,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('心','心',null,61,array['kvg:0611f-g15']::text[],array['kvg:0611f-s10','kvg:0611f-s11','kvg:0611f-s12','kvg:0611f-s13']::text[],'kvg:0611f-g15',4,24863,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('忄','忄','心',61,array['kvg:061be-g1']::text[],array['kvg:061be-s1','kvg:061be-s2','kvg:061be-s3']::text[],'kvg:061be-g1',0,25022,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
(null,null,null,null,array[]::text[],array['kvg:061be-s4']::text[],'kvg:061be-s4',1,25022,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('戈','戈',null,62,array['kvg:061be-g6','kvg:061be-g12']::text[],array['kvg:061be-s5','kvg:061be-s10','kvg:061be-s11','kvg:061be-s12']::text[],'kvg:061be-g6',2,25022,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('一','一',null,1,array['kvg:061be-g9']::text[],array['kvg:061be-s6']::text[],'kvg:061be-g9',3,25022,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('口','口',null,30,array['kvg:061be-g10']::text[],array['kvg:061be-s7','kvg:061be-s8','kvg:061be-s9']::text[],'kvg:061be-g10',4,25022,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('心','心',null,61,array['kvg:061be-g17']::text[],array['kvg:061be-s13','kvg:061be-s14','kvg:061be-s15','kvg:061be-s16']::text[],'kvg:061be-g17',5,25022,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('木','木',null,75,array['kvg:06a5f-g1']::text[],array['kvg:06a5f-s1','kvg:06a5f-s2','kvg:06a5f-s3','kvg:06a5f-s4']::text[],'kvg:06a5f-g1',0,27231,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('幺','幺',null,52,array['kvg:06a5f-g3']::text[],array['kvg:06a5f-s5','kvg:06a5f-s6','kvg:06a5f-s7']::text[],'kvg:06a5f-g3',1,27231,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('幺','幺',null,52,array['kvg:06a5f-g4']::text[],array['kvg:06a5f-s8','kvg:06a5f-s9','kvg:06a5f-s10']::text[],'kvg:06a5f-g4',2,27231,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('戈','戈',null,62,array['kvg:06a5f-g6','kvg:06a5f-g12']::text[],array['kvg:06a5f-s11','kvg:06a5f-s14','kvg:06a5f-s15','kvg:06a5f-s16']::text[],'kvg:06a5f-g6',3,27231,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('人','人',null,9,array['kvg:06a5f-g9']::text[],array['kvg:06a5f-s12','kvg:06a5f-s13']::text[],'kvg:06a5f-g9',4,27231,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('止','止',null,77,array['kvg:06b73-g1']::text[],array['kvg:06b73-s1','kvg:06b73-s2','kvg:06b73-s3','kvg:06b73-s4']::text[],'kvg:06b73-g1',0,27507,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('厂','厂',null,27,array['kvg:06b73-g4']::text[],array['kvg:06b73-s5','kvg:06b73-s6']::text[],'kvg:06b73-g4',1,27507,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('一','一',null,1,array['kvg:06b73-g7']::text[],array['kvg:06b73-s7']::text[],'kvg:06b73-g7',2,27507,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('小','小',null,42,array['kvg:06b73-g8']::text[],array['kvg:06b73-s8','kvg:06b73-s9','kvg:06b73-s10']::text[],'kvg:06b73-g8',3,27507,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
(null,null,null,null,array[]::text[],array['kvg:06b73-s11']::text[],'kvg:06b73-s11',4,27507,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('丿','丿',null,4,array['kvg:06b73-g12']::text[],array['kvg:06b73-s12']::text[],'kvg:06b73-g12',5,27507,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('丶','丶',null,3,array['kvg:06b73-g14']::text[],array['kvg:06b73-s13']::text[],'kvg:06b73-g14',6,27507,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('氵','氵','水',85,array['kvg:06e1b-g1']::text[],array['kvg:06e1b-s1','kvg:06e1b-s2','kvg:06e1b-s3']::text[],'kvg:06e1b-g1',0,28187,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
(null,null,null,null,array[]::text[],array['kvg:06e1b-s4']::text[],'kvg:06e1b-s4',1,28187,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('戈','戈',null,62,array['kvg:06e1b-g5','kvg:06e1b-g11']::text[],array['kvg:06e1b-s5','kvg:06e1b-s10','kvg:06e1b-s11','kvg:06e1b-s12']::text[],'kvg:06e1b-g5',2,28187,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('一','一',null,1,array['kvg:06e1b-g8']::text[],array['kvg:06e1b-s6']::text[],'kvg:06e1b-g8',3,28187,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('口','口',null,30,array['kvg:06e1b-g9']::text[],array['kvg:06e1b-s7','kvg:06e1b-s8','kvg:06e1b-s9']::text[],'kvg:06e1b-g9',4,28187,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('氵','氵','水',85,array['kvg:06ec5-g1']::text[],array['kvg:06ec5-s1','kvg:06ec5-s2','kvg:06ec5-s3']::text[],'kvg:06ec5-g1',0,28357,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
(null,null,null,null,array[]::text[],array['kvg:06ec5-s4']::text[],'kvg:06ec5-s4',1,28357,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('戈','戈',null,62,array['kvg:06ec5-g5','kvg:06ec5-g11']::text[],array['kvg:06ec5-s5','kvg:06ec5-s11','kvg:06ec5-s12','kvg:06ec5-s13']::text[],'kvg:06ec5-g5',2,28357,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('一','一',null,1,array['kvg:06ec5-g8']::text[],array['kvg:06ec5-s6']::text[],'kvg:06ec5-g8',3,28357,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('火','火',null,86,array['kvg:06ec5-g9']::text[],array['kvg:06ec5-s7','kvg:06ec5-s8','kvg:06ec5-s9','kvg:06ec5-s10']::text[],'kvg:06ec5-g9',4,28357,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('艹','艹','艸',140,array['kvg:08511-g1']::text[],array['kvg:08511-s1','kvg:08511-s2','kvg:08511-s3']::text[],'kvg:08511-g1',0,34065,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('罒','罒','网',122,array['kvg:08511-g3']::text[],array['kvg:08511-s4','kvg:08511-s5','kvg:08511-s6','kvg:08511-s7','kvg:08511-s8']::text[],'kvg:08511-g3',1,34065,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
(null,null,null,null,array[]::text[],array['kvg:08511-s9']::text[],'kvg:08511-s9',2,34065,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('戈','戈',null,62,array['kvg:08511-g7','kvg:08511-g11']::text[],array['kvg:08511-s10','kvg:08511-s12','kvg:08511-s13','kvg:08511-s14']::text[],'kvg:08511-g7',3,34065,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f'),
('一','一',null,1,array['kvg:08511-g10']::text[],array['kvg:08511-s11']::text[],'kvg:08511-g10',4,34065,2,'55b5ba92a7cad78a62ef04db4be6f9562d949b7f');

delete from public.kanji_components
where kanji_id in (23041,24190,24863,25022,27231,27507,28187,28357,34065);

insert into public.kanji_components(kanji_id,radical_id,component_form,sort_order)
select kanji_id,radical_id,display_form,min(sort_order)
from public.kanji_component_occurrences
where kanji_id in (23041,24190,24863,25022,27231,27507,28187,28357,34065)
  and radical_id is not null
group by kanji_id,radical_id,display_form;

commit;
