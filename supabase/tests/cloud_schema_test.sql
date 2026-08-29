begin;

select plan(14);
select has_table('public', 'folders', 'folders exists');
select has_table('public', 'vocabulary', 'vocabulary exists');
select has_table('public', 'srs_progress', 'srs_progress exists');
select has_table('public', 'user_learning_settings', 'settings exists');
select has_column('public', 'folders', 'sort_order', 'folder order exists');
select has_column('public', 'folders', 'is_study_paused', 'folder study pause exists');
select has_column('public', 'vocabulary', 'tts_text', 'vocabulary TTS text exists');
select has_function(
  'public',
  'assign_folder_sort_order',
  array[]::text[],
  'folder sort assignment trigger function exists'
);
select ok(
  exists (
    select 1
    from pg_trigger
    where tgrelid = 'public.folders'::regclass
      and tgname = 'folders_assign_sort_order'
      and not tgisinternal
  ),
  'folder sort assignment trigger exists'
);
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
