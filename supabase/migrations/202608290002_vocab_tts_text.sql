alter table public.vocabulary
add column if not exists tts_text text;

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
        pitch_accent, tts_text, example, note
      ) values (
        auth.uid(), target_folder_id, nullif(item->>'kanji', ''),
        item->>'kana', item->>'romaji', item->>'meaning',
        nullif(item->>'pitch_accent', ''), nullif(item->>'tts_text', ''),
        nullif(item->>'example', ''), nullif(item->>'note', '')
      ) returning id into target_vocab_id;
      inserted_count := inserted_count + 1;
    else
      update public.vocabulary set
        kanji = nullif(item->>'kanji', ''), romaji = item->>'romaji',
        meaning = item->>'meaning',
        pitch_accent = nullif(item->>'pitch_accent', ''),
        tts_text = case
          when item ? 'tts_text' then nullif(item->>'tts_text', '')
          else tts_text
        end,
        example = nullif(item->>'example', ''),
        note = nullif(item->>'note', '')
      where id = existing_id and user_id = auth.uid();
      target_vocab_id := existing_id;
      updated_count := updated_count + 1;
    end if;

    if item ? 'level' or item ? 'next_review' or item ? 'last_review' then
      update public.srs_progress set
        level = coalesce((item->>'level')::smallint, level),
        interval_days =
          coalesce((item->>'interval_days')::double precision, interval_days),
        next_review_at =
          coalesce((item->>'next_review')::timestamptz, next_review_at),
        last_reviewed_at = case
          when item ? 'last_review'
            then nullif(item->>'last_review', '')::timestamptz
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

revoke all on function public.import_vocabulary(uuid, jsonb, text)
from public, anon;
grant execute on function public.import_vocabulary(uuid, jsonb, text)
to authenticated;
