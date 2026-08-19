create or replace function public.assign_folder_sort_order()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.sort_order is null then
    perform pg_advisory_xact_lock(hashtextextended(new.user_id::text, 1));
    set constraints folders_user_sort_order_key deferred;

    update public.folders as folder
    set sort_order = folder.sort_order + 1
    where folder.user_id = new.user_id;

    new.sort_order = 0;
  end if;
  return new;
end;
$$;

revoke all on function public.assign_folder_sort_order() from public;
