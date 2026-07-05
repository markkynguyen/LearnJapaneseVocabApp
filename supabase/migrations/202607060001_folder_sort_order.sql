alter table public.folders add column sort_order integer;

with ranked as (
  select
    id,
    row_number() over (
      partition by user_id
      order by created_at desc, id
    ) - 1 as position
  from public.folders
)
update public.folders as folder
set sort_order = ranked.position
from ranked
where folder.id = ranked.id;

alter table public.folders
  alter column sort_order set not null;

alter table public.folders
  add constraint folders_user_sort_order_key
  unique (user_id, sort_order)
  deferrable initially deferred;

create or replace function public.assign_folder_sort_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.sort_order is null then
    perform pg_advisory_xact_lock(hashtextextended(new.user_id::text, 1));
    select coalesce(max(folder.sort_order) + 1, 0)
      into new.sort_order
    from public.folders as folder
    where folder.user_id = new.user_id;
  end if;
  return new;
end;
$$;

create trigger folders_assign_sort_order
before insert on public.folders
for each row execute function public.assign_folder_sort_order();

drop function public.get_folder_summaries();

create function public.get_folder_summaries()
returns table (
  id uuid, name varchar, description text, color varchar,
  sort_order integer, created_at timestamptz, updated_at timestamptz,
  total_words bigint, unlearned_count bigint, due_count bigint, lv6_count bigint
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

create or replace function public.reorder_folders(ordered_ids uuid[])
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  owned_count integer;
begin
  if uid is null then
    raise exception 'authentication required';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(uid::text, 1));

  select count(*) into owned_count
  from public.folders
  where user_id = uid;

  if ordered_ids is null
      or cardinality(ordered_ids) <> owned_count
      or cardinality(ordered_ids) <> (
        select count(distinct ids.folder_id)
        from unnest(ordered_ids) as ids(folder_id)
      )
      or exists (
        select 1
        from unnest(ordered_ids) as ids(folder_id)
        left join public.folders as folder
          on folder.id = ids.folder_id and folder.user_id = uid
        where folder.id is null
      ) then
    raise exception 'invalid folder order';
  end if;

  set constraints folders_user_sort_order_key deferred;

  update public.folders as folder
  set sort_order = (ordered.position - 1)::integer
  from unnest(ordered_ids) with ordinality as ordered(id, position)
  where folder.id = ordered.id and folder.user_id = uid;
end;
$$;

revoke all on function public.assign_folder_sort_order() from public;
revoke all on function public.get_folder_summaries() from public, anon;
revoke all on function public.reorder_folders(uuid[]) from public, anon;
grant execute on function public.reorder_folders(uuid[]) to authenticated;
grant execute on function public.get_folder_summaries() to authenticated;
