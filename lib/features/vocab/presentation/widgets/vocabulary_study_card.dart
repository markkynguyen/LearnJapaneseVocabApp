import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import 'pitch_accent_text.dart';

class VocabularyStudyCard extends StatelessWidget {
  const VocabularyStudyCard({
    required this.vocab,
    this.emptyDetailsMessage = 'Đã sẵn sàng để luyện tập',
    this.framed = true,
    super.key,
  });

  final VocabularyEntry vocab;
  final String? emptyDetailsMessage;
  final bool framed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasKanji = vocab.kanji?.trim().isNotEmpty == true;
    final hasNote = vocab.note?.trim().isNotEmpty == true;
    final hasExample = vocab.example?.trim().isNotEmpty == true;

    final content = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.08),
            colors.surface,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.auto_stories_rounded,
                color: colors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            if (hasKanji) ...[
              Center(
                child: Text(
                  vocab.kanji!.trim(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            Center(
              child: PitchAccentText(
                kana: vocab.kana,
                pattern: vocab.pitchAccent,
                fontSize: hasKanji ? 24 : 36,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                vocab.romaji,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Nghĩa',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    vocab.meaning,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
            ),
            if (hasNote)
              _DetailSection(
                icon: Icons.edit_note_rounded,
                title: 'Ghi chú',
                value: vocab.note!.trim(),
              ),
            if (hasExample)
              _DetailSection(
                icon: Icons.notes_rounded,
                title: 'Ví dụ',
                value: vocab.example!.trim(),
              ),
            if (!hasNote &&
                !hasExample &&
                emptyDetailsMessage?.isNotEmpty == true) ...[
              const SizedBox(height: 18),
              Center(
                child: Text(
                  emptyDetailsMessage!,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!framed) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: content,
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(height: 1.45)),
        ],
      ),
    );
  }
}
