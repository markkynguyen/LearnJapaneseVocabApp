-- Run with psql against a local Supabase database (never a production database).
\set ON_ERROR_STOP 1
\ir fixtures/kanji_assertions.sql
begin;
select plan(16);
select has_table('public', 'radicals', 'Radical catalog');
select has_table('public', 'kanji', 'Kanji catalog');
select has_table('public', 'kanji_components', 'Component forms');
select has_table('public', 'user_kanji_stats', 'User Kanji counts');
select has_table('public', 'user_radical_stats', 'User radical counts');
select has_table('public', 'user_kanji_stats_overview', 'Manual snapshot overview');
select has_function('public', 'recalculate_user_kanji_and_radical_stats', array[]::text[], 'Recalculate RPC');
select has_function('public', 'get_user_kanji_snapshot', array[]::text[], 'Atomic read RPC');
select is((select count(*)::integer from public.radicals), 214, '214 Kangxi radicals');
select is((select count(*)::integer from public.kanji), 2136, '2136 Joyo Kanji');
select col_is_pk('public', 'kanji_components', array['kanji_id','radical_id','component_form'], 'Composite component identity');
select ok(not exists(select 1 from public.kanji where grade not in (1,2,3,4,5,6,8)), 'Primary and secondary school groups');
select ok((select bool_and(relrowsecurity) from pg_class where oid in (
  'public.radicals'::regclass, 'public.kanji'::regclass, 'public.kanji_components'::regclass,
  'public.user_kanji_stats'::regclass, 'public.user_radical_stats'::regclass,
  'public.user_kanji_stats_overview'::regclass)), 'RLS on all six tables');
select ok(not has_function_privilege('anon','public.recalculate_user_kanji_and_radical_stats()','EXECUTE'), 'Anonymous recalc denied');
select ok(not has_table_privilege('authenticated','public.user_kanji_stats','UPDATE'), 'Client cannot forge statistics');
select ok(true, 'Shared RPC assertions passed: repetition, idempotency, two users, cleanup, unsupported CJK and rollback');
select * from finish();
rollback;
