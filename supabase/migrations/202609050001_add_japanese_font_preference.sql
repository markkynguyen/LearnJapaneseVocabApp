alter table public.device_preferences
  add column japanese_font text not null default 'klee_one'
  check (japanese_font in ('klee_one', 'biz_udpgothic'));
