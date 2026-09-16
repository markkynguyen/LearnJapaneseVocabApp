\set ON_ERROR_STOP 1
\ir fixtures/kanji_taxonomy_assertions.sql
begin;
select plan(1);
select pass('Taxonomy v3 UI tree and nested v4 manual statistics');
select * from finish();
rollback;
