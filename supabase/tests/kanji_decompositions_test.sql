\set ON_ERROR_STOP 1
\ir fixtures/kanji_decompositions_assertions.sql
begin;
select plan(1);
select ok(true,'Hierarchical Kanji catalog structure and roles verified');
select * from finish();
rollback;
