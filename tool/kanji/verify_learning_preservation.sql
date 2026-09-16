-- Read-only fingerprints, no learning content or credentials returned.
select 'vocabulary' as table_name, count(*) as rows,
  md5(coalesce(string_agg(to_jsonb(t)::text, '' order by id), '')) as fingerprint from public.vocabulary t
union all select 'folders', count(*),
  md5(coalesce(string_agg(to_jsonb(t)::text, '' order by id), '')) from public.folders t
union all select 'srs_progress', count(*),
  md5(coalesce(string_agg(to_jsonb(t)::text, '' order by vocab_id), '')) from public.srs_progress t
union all select 'user_learning_settings', count(*),
  md5(coalesce(string_agg(to_jsonb(t)::text, '' order by user_id), '')) from public.user_learning_settings t
union all select 'device_preferences', count(*),
  md5(coalesce(string_agg(to_jsonb(t)::text, '' order by user_id, device_id), '')) from public.device_preferences t
union all select 'auth.users', count(*),
  md5(coalesce(string_agg(to_jsonb(t)::text, '' order by id), '')) from auth.users t;
