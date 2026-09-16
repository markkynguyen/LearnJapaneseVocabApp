begin;

-- Hiển thị các dạng bộ thủ theo số lần xuất hiện của chính dạng đó.
-- Các biến thể chưa từng xuất hiện vẫn được giữ trong catalog để màn chi tiết
-- có thể điều hướng đầy đủ, nhưng không đưa vào danh sách radical_forms.
create or replace function public.get_user_kanji_snapshot() returns jsonb
language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'overview', (select to_jsonb(o) from public.user_kanji_stats_overview o where o.user_id = auth.uid()),
    'kanji', coalesce((select jsonb_agg(to_jsonb(k) || jsonb_build_object('count', s.count) order by s.count desc, k.id)
      from public.user_kanji_stats s join public.kanji k on k.id = s.kanji_id where s.user_id = auth.uid()), '[]'::jsonb),
    'radicals', coalesce((select jsonb_agg(to_jsonb(r) || jsonb_build_object('count', s.count) order by s.count desc, r.id)
      from public.user_radical_stats s join public.radicals r on r.id = s.radical_id where s.user_id = auth.uid()), '[]'::jsonb),
    'radical_forms', coalesce((
      with form_counts as (
        select c.radical_id, c.component_form, sum(s.count) as count
        from public.user_kanji_stats s
        join (
          select distinct kanji_id, radical_id, component_form
          from public.kanji_components
        ) c on c.kanji_id = s.kanji_id
        where s.user_id = auth.uid()
        group by c.radical_id, c.component_form
      )
      select jsonb_agg(
        to_jsonb(r) || jsonb_build_object(
          'form', f.form,
          'count', fc.count,
          'family_count', family.count,
          'is_original', f.form_order = 0,
          'form_order', f.form_order
        )
        order by fc.count desc, r.id, f.form_order
      )
      from public.user_radical_stats family
      join public.radicals r on r.id = family.radical_id
      cross join lateral (
        select r.character as form, 0::bigint as form_order
        union all
        select variant, ordinal
        from unnest(r.variants) with ordinality as variants(variant, ordinal)
      ) f
      join form_counts fc
        on fc.radical_id = r.id and fc.component_form = f.form
      where family.user_id = auth.uid()
    ), '[]'::jsonb)
  );
$$;

commit;
