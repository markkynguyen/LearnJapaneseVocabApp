alter table public.user_learning_settings
  drop constraint if exists user_learning_settings_quiz_japanese_script_check;

alter table public.user_learning_settings
  add constraint user_learning_settings_quiz_japanese_script_check
  check (quiz_japanese_script in ('kanji', 'kana', 'both'));
