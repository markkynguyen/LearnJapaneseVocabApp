begin;

create table public.radicals (
  id smallint primary key check (id between 1 and 214),
  character text not null unique check (char_length(character) = 1),
  name_vi text not null,
  meaning_vi text not null,
  stroke_count smallint not null check (stroke_count > 0),
  variants text[] not null default '{}',
  positions text[] not null default '{}'
);
create table public.kanji (
  id integer primary key,
  character text not null unique check (char_length(character) = 1),
  han_viet text,
  onyomi text[] not null default '{}',
  kunyomi text[] not null default '{}',
  meaning_vi text,
  meaning_en text not null,
  stroke_count smallint not null check (stroke_count > 0),
  grade smallint not null check (grade in (1,2,3,4,5,6,8)),
  primary_radical_id smallint not null references public.radicals(id),
  translation_reviewed boolean not null default false
);
create table public.kanji_components (
  kanji_id integer not null references public.kanji(id) on delete cascade,
  radical_id smallint not null references public.radicals(id),
  component_form text not null check (char_length(component_form) = 1),
  sort_order smallint not null check (sort_order >= 0),
  primary key (kanji_id, radical_id, component_form)
);
create index kanji_components_radical_idx on public.kanji_components(radical_id, kanji_id);
create table public.user_kanji_stats (
  user_id uuid not null references auth.users(id) on delete cascade,
  kanji_id integer not null references public.kanji(id),
  count bigint not null check (count > 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, kanji_id)
);
create table public.user_radical_stats (
  user_id uuid not null references auth.users(id) on delete cascade,
  radical_id smallint not null references public.radicals(id),
  count bigint not null check (count > 0),
  updated_at timestamptz not null default now(),
  primary key (user_id, radical_id)
);
create table public.user_kanji_stats_overview (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_calculated_at timestamptz not null,
  total_kanji_count integer not null check (total_kanji_count >= 0),
  total_radical_count integer not null check (total_radical_count >= 0),
  total_vocab_scanned bigint not null check (total_vocab_scanned >= 0),
  unsupported_kanji_count integer not null check (unsupported_kanji_count >= 0),
  updated_at timestamptz not null default now()
);

alter table public.radicals enable row level security;
alter table public.kanji enable row level security;
alter table public.kanji_components enable row level security;
alter table public.user_kanji_stats enable row level security;
alter table public.user_radical_stats enable row level security;
alter table public.user_kanji_stats_overview enable row level security;
create policy radicals_read on public.radicals for select to authenticated using (true);
create policy kanji_read on public.kanji for select to authenticated using (true);
create policy kanji_components_read on public.kanji_components for select to authenticated using (true);
create policy kanji_stats_owner on public.user_kanji_stats for select to authenticated using (user_id = (select auth.uid()));
create policy radical_stats_owner on public.user_radical_stats for select to authenticated using (user_id = (select auth.uid()));
create policy kanji_overview_owner on public.user_kanji_stats_overview for select to authenticated using (user_id = (select auth.uid()));
revoke all on public.radicals, public.kanji, public.kanji_components,
  public.user_kanji_stats, public.user_radical_stats, public.user_kanji_stats_overview from anon, authenticated;
grant select on public.radicals, public.kanji, public.kanji_components,
  public.user_kanji_stats, public.user_radical_stats, public.user_kanji_stats_overview to authenticated;

-- Cùng phạm vi Unicode với extractKanjiCharacters ở Flutter. Không tính kana,
-- dấu lặp 々 hay variation selector là chữ Hán chưa hỗ trợ.
create function public.is_kanji_codepoint(cp integer) returns boolean
language sql immutable parallel safe set search_path = '' as $$
  select cp between 13312 and 19903 or cp between 19968 and 40959
    or cp between 63744 and 64255 or cp between 131072 and 173791
    or cp between 173824 and 177983 or cp between 177984 and 178207
    or cp between 178208 and 183983 or cp between 183984 and 191471
    or cp between 191472 and 192095 or cp between 194560 and 195103
    or cp between 196608 and 201551 or cp between 201552 and 205743
    or cp between 205744 and 210047;
$$;

create function public.recalculate_user_kanji_and_radical_stats() returns void
language plpgsql security definer set search_path = '' as $$
declare
  uid uuid := auth.uid();
  snapshot jsonb;
  scanned bigint;
  calculated timestamptz;
begin
  if uid is null then raise exception 'authentication required'; end if;
  -- Hai thiết bị của cùng người dùng không thể ghi đè xen kẽ các bảng thống kê.
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('kanji:' || uid::text, 0));
  calculated := clock_timestamp();
  -- Chụp cả số từ và số ký tự trong cùng một SQL snapshot trước khi ghi kết quả.
  with vocab as materialized (
    select v.kanji from public.vocabulary v
    where v.user_id = uid
  ), chars as (
    select ch, count(*) as count
    from vocab v cross join lateral regexp_split_to_table(v.kanji, '') ch
    where public.is_kanji_codepoint(ascii(ch)) group by ch
  )
  select (select count(*) from vocab),
    coalesce((select jsonb_agg(jsonb_build_object('character', ch, 'count', count)) from chars), '[]'::jsonb)
  into scanned, snapshot;

  delete from public.user_radical_stats where user_id = uid;
  delete from public.user_kanji_stats where user_id = uid;
  insert into public.user_kanji_stats(user_id, kanji_id, count, updated_at)
  select uid, k.id, c.count, calculated
  from jsonb_to_recordset(snapshot) c(character text, count bigint)
  join public.kanji k on k.character = c.character;
  insert into public.user_radical_stats(user_id, radical_id, count, updated_at)
  select uid, c.radical_id, sum(s.count), calculated
  from public.user_kanji_stats s
  join (select distinct kanji_id, radical_id from public.kanji_components) c on c.kanji_id = s.kanji_id
  where s.user_id = uid group by c.radical_id;
  insert into public.user_kanji_stats_overview(user_id, last_calculated_at,
    total_kanji_count, total_radical_count, total_vocab_scanned, unsupported_kanji_count, updated_at)
  values (uid, calculated,
    (select count(*) from public.user_kanji_stats where user_id = uid),
    (select count(*) from public.user_radical_stats where user_id = uid), scanned,
    (select count(*) from jsonb_to_recordset(snapshot) c(character text, count bigint)
      where not exists (select 1 from public.kanji k where k.character = c.character)), calculated)
  on conflict (user_id) do update set last_calculated_at = excluded.last_calculated_at,
    total_kanji_count = excluded.total_kanji_count, total_radical_count = excluded.total_radical_count,
    total_vocab_scanned = excluded.total_vocab_scanned, unsupported_kanji_count = excluded.unsupported_kanji_count,
    updated_at = excluded.updated_at;
end;
$$;

-- Một kết quả JSON duy nhất tránh trộn overview/lưới của hai lần tính khác nhau
-- và giới hạn mặc định 1000 hàng của PostgREST.
create function public.get_user_kanji_snapshot() returns jsonb
language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'overview', (select to_jsonb(o) from public.user_kanji_stats_overview o where o.user_id = auth.uid()),
    'kanji', coalesce((select jsonb_agg(to_jsonb(k) || jsonb_build_object('count', s.count) order by s.count desc, k.id)
      from public.user_kanji_stats s join public.kanji k on k.id = s.kanji_id where s.user_id = auth.uid()), '[]'::jsonb),
    'radicals', coalesce((select jsonb_agg(to_jsonb(r) || jsonb_build_object('count', s.count) order by s.count desc, r.id)
      from public.user_radical_stats s join public.radicals r on r.id = s.radical_id where s.user_id = auth.uid()), '[]'::jsonb)
  );
$$;
revoke all on function public.is_kanji_codepoint(integer) from public, anon;
grant execute on function public.is_kanji_codepoint(integer) to authenticated;
revoke all on function public.recalculate_user_kanji_and_radical_stats() from public, anon;
revoke all on function public.get_user_kanji_snapshot() from public, anon;
grant execute on function public.recalculate_user_kanji_and_radical_stats() to authenticated;
grant execute on function public.get_user_kanji_snapshot() to authenticated;
commit;
