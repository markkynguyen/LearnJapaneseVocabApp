\set ON_ERROR_STOP 1
\ir fixtures/kanji_occurrences_assertions.sql
begin;
select plan(3);
select has_table('public','kanji_component_occurrences','Occurrence catalog');
select has_column('public','user_kanji_stats_overview','component_version','Snapshot rule version');
select ok(true,'Occurrence coverage, stop rules, old snapshot, manual update and counts passed');
select * from finish();
rollback;
