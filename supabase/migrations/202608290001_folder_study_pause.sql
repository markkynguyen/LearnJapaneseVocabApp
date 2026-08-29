alter table public.folders
  add column is_study_paused boolean not null default false;

drop function public.get_folder_summaries();

create function public.get_folder_summaries()
returns table (
  id uuid,
  name varchar,
  description text,
  color varchar,
  is_study_paused boolean,
  sort_order integer,
  created_at timestamptz,
  updated_at timestamptz,
  total_words bigint,
  unlearned_count bigint,
  due_count bigint,
  lv6_count bigint
)
language sql
security invoker
set search_path = public
as $$
  select
    f.id,
    f.name,
    f.description,
    f.color,
    f.is_study_paused,
    f.sort_order,
    f.created_at,
    f.updated_at,
    count(v.id),
    count(v.id) filter (where sp.level = 0),
    count(v.id) filter (where sp.level > 0 and sp.next_review_at <= now()),
    count(v.id) filter (where sp.level = 6)
  from public.folders f
  left join public.vocabulary v on v.folder_id = f.id
  left join public.srs_progress sp on sp.vocab_id = v.id
  where f.user_id = auth.uid()
  group by f.id
  order by f.sort_order, f.created_at, f.id;
$$;

revoke all on function public.get_folder_summaries() from public, anon;
grant execute on function public.get_folder_summaries() to authenticated;
