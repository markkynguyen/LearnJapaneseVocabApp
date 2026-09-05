import 'package:flutter/material.dart';

import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_typography.dart';

class JapaneseFontCard extends StatelessWidget {
  const JapaneseFontCard({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final JapaneseFontChoice selected;
  final ValueChanged<JapaneseFontChoice> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.text_format_rounded, color: colors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Phông chữ tiếng Nhật',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Áp dụng đồng bộ cho kana và kanji trong nội dung học.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            for (final choice in JapaneseFontChoice.values) ...[
              _FontOption(
                choice: choice,
                selected: selected == choice,
                onTap: () => onChanged(choice),
              ),
              if (choice != JapaneseFontChoice.values.last)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _FontOption extends StatelessWidget {
  const _FontOption({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final JapaneseFontChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (title, subtitle) = switch (choice) {
      JapaneseFontChoice.textbook => (
          'Kiểu sách giáo khoa',
          'Klee One · Mặc định',
        ),
      JapaneseFontChoice.clearModern => (
          'Nét rõ hiện đại',
          'BIZ UDPGothic',
        ),
    };
    return Material(
      color: selected ? colors.primary.withValues(alpha: 0.09) : null,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '先生　せんせい　センセイ',
                      locale: AppTypography.japaneseLocale,
                      style: AppTypography.japaneseForChoice(
                        choice,
                        Theme.of(context).textTheme.titleMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
