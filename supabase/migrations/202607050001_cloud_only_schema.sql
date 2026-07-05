create extension if not exists pgcrypto;

create table public.folders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name varchar(50) not null check (length(trim(name)) > 0),
  description text,
  color varchar(9) not null default '#6366F1',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.vocabulary (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  folder_id uuid not null references public.folders(id) on delete cascade,
  kanji text,
  kana text not null check (length(trim(kana)) > 0),
  romaji text not null check (length(trim(romaji)) > 0),
  meaning text not null check (length(trim(meaning)) > 0),
  pitch_accent text,
  example text,
  note text,
  is_favorite boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.srs_progress (
  vocab_id uuid primary key references public.vocabulary(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  level smallint not null default 0 check (level between 0 and 6),
  interval_days double precision not null default 0 check (interval_days >= 0),
  next_review_at timestamptz not null default to_timestamp(0),
  correct_count integer not null default 0 check (correct_count >= 0),
  wrong_count integer not null default 0 check (wrong_count >= 0),
  last_reviewed_at timestamptz,
  updated_at timestamptz not null default now()
);

create table public.user_learning_settings (
  user_id uuid primary key references auth.users(id) on delete cascade,
  session_size integer not null default 10 check (session_size between 1 and 100),
  quiz_direction text not null default 'ja_to_vi',
  quiz_listen_count integer not null default 1 check (quiz_listen_count between 0 and 10),
  quiz_read_count integer not null default 1 check (quiz_read_count between 0 and 10),
  quiz_write_count integer not null default 1 check (quiz_write_count between 0 and 10),
  quiz_choose_word_count integer not null default 1 check (quiz_choose_word_count between 0 and 10),
  quiz_choose_meaning_count integer not null default 1 check (quiz_choose_meaning_count between 0 and 10),
  quiz_retry_limit integer not null default 2 check (quiz_retry_limit between 0 and 5),
  new_word_session_size integer not null default 5 check (new_word_session_size between 1 and 100),
  new_word_listen_count integer not null default 1 check (new_word_listen_count between 0 and 10),
  new_word_write_count integer not null default 1 check (new_word_write_count between 0 and 10),
  new_word_choose_word_count integer not null default 1 check (new_word_choose_word_count between 0 and 10),
  new_word_choose_meaning_count integer not null default 1 check (new_word_choose_meaning_count between 0 and 10),
  quiz_japanese_script text not null default 'kanji' check (quiz_japanese_script in ('kanji', 'kana')),
  srs_level_1_interval_days double precision not null default (2.0 / 24.0),
  srs_level_2_interval_days double precision not null default 1,
  srs_level_3_interval_days double precision not null default 2,
  srs_level_4_interval_days double precision not null default 3,
  srs_level_5_interval_days double precision not null default 5,
  srs_level_6_interval_days double precision not null default 8,
  flashcard_show_kana boolean not null default true,
  flashcard_show_romaji boolean not null default true,
  updated_at timestamptz not null default now()
);

create table public.device_preferences (
  user_id uuid not null references auth.users(id) on delete cascade,
  device_id text not null,
  theme_mode text not null default 'light' check (theme_mode in ('light', 'dark')),
  notify_enabled boolean not null default false,
  notify_hour smallint not null default 8 check (notify_hour between 0 and 23),
  notify_minute smallint not null default 0 check (notify_minute between 0 and 59),
  updated_at timestamptz not null default now(),
  primary key (user_id, device_id)
);

create index folders_user_id_idx on public.folders(user_id);
create index vocabulary_user_folder_idx on public.vocabulary(user_id, folder_id);
create index vocabulary_search_idx on public.vocabulary(user_id, kana, romaji);
create index srs_progress_user_due_idx on public.srs_progress(user_id, next_review_at);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger folders_updated_at before update on public.folders
for each row execute function public.set_updated_at();
create trigger vocabulary_updated_at before update on public.vocabulary
for each row execute function public.set_updated_at();
create trigger srs_progress_updated_at before update on public.srs_progress
for each row execute function public.set_updated_at();
create trigger learning_settings_updated_at before update on public.user_learning_settings
for each row execute function public.set_updated_at();
create trigger device_preferences_updated_at before update on public.device_preferences
for each row execute function public.set_updated_at();

create or replace function public.create_srs_progress()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.srs_progress(vocab_id, user_id)
  values (new.id, new.user_id);
  return new;
end;
$$;

create trigger vocabulary_create_progress after insert on public.vocabulary
for each row execute function public.create_srs_progress();

alter table public.folders enable row level security;
alter table public.vocabulary enable row level security;
alter table public.srs_progress enable row level security;
alter table public.user_learning_settings enable row level security;
alter table public.device_preferences enable row level security;

create policy folders_owner on public.folders for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy vocabulary_owner on public.vocabulary for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy srs_progress_owner on public.srs_progress for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy learning_settings_owner on public.user_learning_settings for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);
create policy device_preferences_owner on public.device_preferences for all to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

create or replace function public.bootstrap_current_user()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  uid uuid := auth.uid();
  hiragana_id uuid;
  katakana_id uuid;
  variant_id uuid;
begin
  if uid is null then raise exception 'authentication required'; end if;
  perform pg_advisory_xact_lock(hashtextextended(uid::text, 0));
  insert into public.user_learning_settings(user_id) values (uid)
  on conflict (user_id) do nothing;

  if not exists (select 1 from public.folders where user_id = uid) then
    insert into public.folders(user_id, name, description, color)
    values (uid, 'Bảng chữ cái Hiragana', 'Bộ chữ hiragana cơ bản.', '#22C55E')
    returning id into hiragana_id;
    insert into public.folders(user_id, name, description, color)
    values (uid, 'Bảng chữ cái Katakana', 'Bộ chữ katakana cơ bản.', '#0EA5E9')
    returning id into katakana_id;
    insert into public.folders(user_id, name, description, color)
    values (uid, 'Biến âm', 'Các âm có dakuten, handakuten và âm ghép.', '#F59E0B')
    returning id into variant_id;

    insert into public.vocabulary(user_id, folder_id, kana, romaji, meaning)
    select uid, hiragana_id, kana, romaji, 'Âm ' || romaji
    from unnest(
      array['あ','い','う','え','お','か','き','く','け','こ','さ','し','す','せ','そ','た','ち','つ','て','と','な','に','ぬ','ね','の','は','ひ','ふ','へ','ほ','ま','み','む','め','も','や','ゆ','よ','ら','り','る','れ','ろ','わ','を','ん'],
      array['a','i','u','e','o','ka','ki','ku','ke','ko','sa','shi','su','se','so','ta','chi','tsu','te','to','na','ni','nu','ne','no','ha','hi','fu','he','ho','ma','mi','mu','me','mo','ya','yu','yo','ra','ri','ru','re','ro','wa','wo','n']
    ) as seed(kana, romaji);

    insert into public.vocabulary(user_id, folder_id, kana, romaji, meaning)
    select uid, katakana_id, kana, romaji, 'Âm ' || romaji
    from unnest(
      array['ア','イ','ウ','エ','オ','カ','キ','ク','ケ','コ','サ','シ','ス','セ','ソ','タ','チ','ツ','テ','ト','ナ','ニ','ヌ','ネ','ノ','ハ','ヒ','フ','ヘ','ホ','マ','ミ','ム','メ','モ','ヤ','ユ','ヨ','ラ','リ','ル','レ','ロ','ワ','ヲ','ン'],
      array['a','i','u','e','o','ka','ki','ku','ke','ko','sa','shi','su','se','so','ta','chi','tsu','te','to','na','ni','nu','ne','no','ha','hi','fu','he','ho','ma','mi','mu','me','mo','ya','yu','yo','ra','ri','ru','re','ro','wa','wo','n']
    ) as seed(kana, romaji);

    insert into public.vocabulary(user_id, folder_id, kana, romaji, meaning)
    select uid, variant_id, kana, romaji, 'Biến âm ' || romaji
    from unnest(
      array['が','ぎ','ぐ','げ','ご','ざ','じ','ず','ぜ','ぞ','だ','ぢ','づ','で','ど','ば','び','ぶ','べ','ぼ','ぱ','ぴ','ぷ','ぺ','ぽ'],
      array['ga','gi','gu','ge','go','za','ji','zu','ze','zo','da','ji','zu','de','do','ba','bi','bu','be','bo','pa','pi','pu','pe','po']
    ) as seed(kana, romaji);
  end if;
end;
$$;

create or replace function public.get_folder_summaries()
returns table (
  id uuid, name varchar, description text, color varchar,
  created_at timestamptz, updated_at timestamptz,
  total_words bigint, unlearned_count bigint, due_count bigint, lv6_count bigint
)
language sql
security invoker
set search_path = public
as $$
  select f.id, f.name, f.description, f.color, f.created_at, f.updated_at,
    count(v.id),
    count(v.id) filter (where sp.level = 0),
    count(v.id) filter (where sp.level > 0 and sp.next_review_at <= now()),
    count(v.id) filter (where sp.level = 6)
  from public.folders f
  left join public.vocabulary v on v.folder_id = f.id
  left join public.srs_progress sp on sp.vocab_id = v.id
  where f.user_id = auth.uid()
  group by f.id
  order by f.created_at desc;
$$;

create or replace function public.apply_srs_updates(payload jsonb)
returns void
language plpgsql
security invoker
set search_path = public
as $$
declare item jsonb;
begin
  for item in select * from jsonb_array_elements(payload)
  loop
    update public.srs_progress set
      level = (item->>'level')::smallint,
      interval_days = (item->>'interval_days')::double precision,
      next_review_at = (item->>'next_review_at')::timestamptz,
      correct_count = (item->>'correct_count')::integer,
      wrong_count = (item->>'wrong_count')::integer,
      last_reviewed_at = nullif(item->>'last_reviewed_at', '')::timestamptz
    where vocab_id = (item->>'vocab_id')::uuid and user_id = auth.uid();
    if not found then raise exception 'invalid vocabulary ownership'; end if;
  end loop;
end;
$$;

create or replace function public.import_vocabulary(
  target_folder_id uuid,
  payload jsonb,
  duplicate_strategy text default 'skip'
)
returns jsonb
language plpgsql
security invoker
set search_path = public
as $$
declare
  item jsonb;
  existing_id uuid;
  target_vocab_id uuid;
  inserted_count integer := 0;
  updated_count integer := 0;
  skipped_count integer := 0;
begin
  if duplicate_strategy not in ('skip', 'overwrite') then
    raise exception 'invalid duplicate strategy';
  end if;
  if not exists (
    select 1 from public.folders
    where id = target_folder_id and user_id = auth.uid()
  ) then
    raise exception 'invalid folder ownership';
  end if;

  for item in select * from jsonb_array_elements(payload)
  loop
    existing_id := null;
    select id into existing_id from public.vocabulary
    where folder_id = target_folder_id and user_id = auth.uid()
      and kana = item->>'kana' order by created_at limit 1;

    if existing_id is not null and duplicate_strategy = 'skip' then
      skipped_count := skipped_count + 1;
      continue;
    end if;

    if existing_id is null then
      insert into public.vocabulary(
        user_id, folder_id, kanji, kana, romaji, meaning,
        pitch_accent, example, note
      ) values (
        auth.uid(), target_folder_id, nullif(item->>'kanji', ''),
        item->>'kana', item->>'romaji', item->>'meaning',
        nullif(item->>'pitch_accent', ''), nullif(item->>'example', ''),
        nullif(item->>'note', '')
      ) returning id into target_vocab_id;
      inserted_count := inserted_count + 1;
    else
      update public.vocabulary set
        kanji = nullif(item->>'kanji', ''), romaji = item->>'romaji',
        meaning = item->>'meaning', pitch_accent = nullif(item->>'pitch_accent', ''),
        example = nullif(item->>'example', ''), note = nullif(item->>'note', '')
      where id = existing_id and user_id = auth.uid();
      target_vocab_id := existing_id;
      updated_count := updated_count + 1;
    end if;

    if item ? 'level' or item ? 'next_review' or item ? 'last_review' then
      update public.srs_progress set
        level = coalesce((item->>'level')::smallint, level),
        interval_days = coalesce((item->>'interval_days')::double precision, interval_days),
        next_review_at = coalesce((item->>'next_review')::timestamptz, next_review_at),
        last_reviewed_at = case
          when item ? 'last_review' then nullif(item->>'last_review', '')::timestamptz
          else last_reviewed_at
        end
      where vocab_id = target_vocab_id and user_id = auth.uid();
    end if;
  end loop;
  return jsonb_build_object(
    'inserted', inserted_count, 'updated', updated_count,
    'skipped', skipped_count, 'failed', 0
  );
end;
$$;

revoke all on function public.bootstrap_current_user() from public, anon;
revoke all on function public.get_folder_summaries() from public, anon;
revoke all on function public.apply_srs_updates(jsonb) from public, anon;
revoke all on function public.import_vocabulary(uuid, jsonb, text) from public, anon;
grant execute on function public.bootstrap_current_user() to authenticated;
grant execute on function public.get_folder_summaries() to authenticated;
grant execute on function public.apply_srs_updates(jsonb) to authenticated;
grant execute on function public.import_vocabulary(uuid, jsonb, text) to authenticated;
