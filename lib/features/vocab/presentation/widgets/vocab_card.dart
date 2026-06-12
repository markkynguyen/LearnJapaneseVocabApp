import 'package:flutter/material.dart';

import '../../../../core/constants/srs_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/time_utils.dart';
import 'pitch_accent_text.dart';
import 'srs_level_badge.dart';

enum VocabCardAction {
  edit,
  minusOne,
  reset,
  delete,
}

class VocabCard extends StatelessWidget {
  const VocabCard({
    required this.item,
    required this.onToggleFavorite,
    required this.onAction,
    super.key,
  });

  final VocabWithProgress item;
  final VoidCallback onToggleFavorite;
  final ValueChanged<VocabCardAction> onAction;

  @override
  Widget build(BuildContext context) {
    final vocab = item.vocab;
    final progress = item.progress;
    final colors = Theme.of(context).colorScheme;
    final levelColor =
        SrsConstants.levelColors[progress.level] ?? colors.primary;
    final background = Color.alphaBlend(
      levelColor.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.58,
      ),
      colors.surface,
    );

    return Card(
      color: background.withValues(alpha: 0.65),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (vocab.kanji?.trim().isNotEmpty ?? false)
                            ? vocab.kanji!.trim()
                            : vocab.kana,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: PitchAccentText(
                              kana: vocab.kana,
                              pattern: vocab.pitchAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              textColor: colors.onSurfaceVariant,
                              accentColor: colors.primary,
                              overlayAccent: true,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '•',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              vocab.romaji,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: vocab.isFavorite
                          ? 'Bỏ yêu thích'
                          : 'Đánh dấu yêu thích',
                      onPressed: onToggleFavorite,
                      icon: Icon(
                        vocab.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: vocab.isFavorite
                            ? context.appDanger
                            : colors.onSurfaceVariant,
                      ),
                    ),
                    SrsLevelBadge(level: progress.level),
                    PopupMenuButton<VocabCardAction>(
                      tooltip: 'Tùy chọn',
                      onSelected: onAction,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: VocabCardAction.edit,
                          child: Text('Sửa từ này'),
                        ),
                        if (progress.level > SrsConstants.unlearnedLevel) ...[
                          const PopupMenuItem(
                            value: VocabCardAction.minusOne,
                            child: Text('Giảm 1 level'),
                          ),
                          const PopupMenuItem(
                            value: VocabCardAction.reset,
                            child: Text('Reset về Lv 1'),
                          ),
                        ],
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: VocabCardAction.delete,
                          child: Text('Xóa từ này'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              vocab.meaning,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (vocab.note?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                vocab.note!.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: colors.onSurfaceVariant,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  progress.level == SrsConstants.unlearnedLevel
                      ? 'Chưa học'
                      : formatNextReview(progress.nextReviewAt),
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
