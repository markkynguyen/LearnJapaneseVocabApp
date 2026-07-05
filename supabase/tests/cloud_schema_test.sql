begin;

select plan(10);
select has_table('public', 'folders', 'folders exists');
select has_table('public', 'vocabulary', 'vocabulary exists');
select has_table('public', 'srs_progress', 'srs_progress exists');
select has_table('public', 'user_learning_settings', 'settings exists');
select has_column('public', 'folders', 'sort_order', 'folder order exists');
select ok(
  (select relrowsecurity from pg_class where oid = 'public.folders'::regclass),
  'folders RLS is active'
);
select has_function('public', 'bootstrap_current_user', array[]::text[], 'bootstrap RPC exists');
select has_function(
  'public',
  'apply_srs_updates',
  array['jsonb'],
  'atomic SRS RPC exists'
);
select has_function(
  'public',
  'import_vocabulary',
  array['uuid', 'jsonb', 'text'],
  'transactional Excel import RPC exists'
);
select has_function(
  'public',
  'reorder_folders',
  array['uuid[]'],
  'transactional folder reorder RPC exists'
);

select * from finish();
rollback;
