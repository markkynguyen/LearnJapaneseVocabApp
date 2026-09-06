\set ON_ERROR_STOP 1
\ir fixtures/kanji_radical_forms_assertions.sql
begin;
select plan(1);
select ok(true,'Radical forms have separate counts and preserve family totals');
select * from finish();
rollback;
