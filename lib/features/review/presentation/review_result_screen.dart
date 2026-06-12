import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_utils.dart';
import '../domain/review_models.dart';
import 'providers/review_session_provider.dart';

class ReviewResultScreen extends ConsumerWidget {
  const ReviewResultScreen({
    required this.summary,
    super.key,
  });

  final ReviewResultSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final scoreColor = _scoreColor(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Kết quả ôn tập'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Icon(
                        _scoreIcon,
                        color: scoreColor,
                        size: 54,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '${summary.percentage}%',
                        style:
                            Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: scoreColor,
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _scoreMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _MetricPill(
                              label: 'Đúng',
                              value: '${summary.correctAnswers}',
                              color: context.appSuccess,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricPill(
                              label: 'Sai',
                              value: '${summary.wrongAnswers}',
                              color: context.appDanger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (summary.leveledUpWords.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SectionTitle(
                  icon: Icons.trending_up_rounded,
                  title: 'Từ được tăng level',
                  count: summary.leveledUpWords.length,
                ),
                const SizedBox(height: 10),
                ...summary.leveledUpWords.map(_ResultWordTile.new),
              ],
              if (summary.wrongWords.isNotEmpty) ...[
                const SizedBox(height: 18),
                _SectionTitle(
                  icon: Icons.replay_rounded,
                  title: 'Từ cần chú ý',
                  count: summary.wrongWords.length,
                ),
                const SizedBox(height: 10),
                ...summary.wrongWords.map(_ResultWordTile.new),
              ],
              const SizedBox(height: 22),
              if (summary.wrongWords.isNotEmpty) ...[
                OutlinedButton.icon(
                  onPressed: () => _reviewWrongWords(context, ref),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Ôn lại từ sai'),
                ),
                const SizedBox(height: 10),
              ],
              FilledButton.icon(
                onPressed: () => _continueReview(context, ref),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Tiếp tục ôn tập'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _returnToSource(context),
                icon: Icon(
                  summary.folderId == null
                      ? Icons.home_rounded
                      : Icons.folder_rounded,
                ),
                label: Text(
                  summary.folderId == null
                      ? 'Trở về trang chủ'
                      : 'Trở về bộ từ',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _reviewWrongWords(BuildContext context, WidgetRef ref) async {
    final wrongWords = summary.wrongWords
        .map((word) => word.reviewResult.item)
        .toList(growable: false);
    if (wrongWords.isEmpty) {
      return;
    }

    await ref.read(reviewSessionControllerProvider.notifier).startWithWords(
          wrongWords,
          folderId: summary.folderId,
          favoritesOnly: summary.favoritesOnly,
        );
    if (!context.mounted) {
      return;
    }
    context.go(AppRoutes.reviewSession);
  }

  Future<void> _continueReview(BuildContext context, WidgetRef ref) async {
    final reviewedIds = summary.words
        .map((word) => word.reviewResult.item.vocab.id)
        .toSet()
        .toList();
    await ref.read(reviewSessionControllerProvider.notifier).start(
          folderId: summary.folderId,
          favoritesOnly: summary.favoritesOnly,
          excludeIds: reviewedIds,
        );

    if (!context.mounted) {
      return;
    }

    final state = ref.read(reviewSessionControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tiếp tục ôn: ${state.error}')),
      );
      return;
    }

    context.go(AppRoutes.reviewSession);
  }

  void _returnToSource(BuildContext context) {
    final folderId = summary.folderId;
    if (folderId == null) {
      context.go(AppRoutes.home);
      return;
    }
    context.go(AppRoutes.folderVocab(folderId));
  }

  Color _scoreColor(BuildContext context) {
    if (summary.percentage >= 80) {
      return context.appSuccess;
    }
    if (summary.percentage >= 50) {
      return context.appWarning;
    }
    return context.appDanger;
  }

  IconData get _scoreIcon {
    if (summary.percentage >= 80) {
      return Icons.emoji_events_rounded;
    }
    if (summary.percentage >= 50) {
      return Icons.auto_awesome_rounded;
    }
    return Icons.psychology_alt_rounded;
  }

  String get _scoreMessage {
    if (summary.percentage >= 80) {
      return 'Rất ổn. Các từ đúng đã được cập nhật lịch ôn mới.';
    }
    if (summary.percentage >= 50) {
      return 'Có tiến bộ rồi. Hãy xem lại những từ còn nhầm.';
    }
    return 'Phiên này hơi khó. Ôn lại từ sai sẽ giúp bạn giữ nhịp.';
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ResultWordTile extends StatelessWidget {
  const _ResultWordTile(this.item);

  final ReviewAppliedWordResult item;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final vocab = item.reviewResult.item.vocab;
    final title = (vocab.kanji?.trim().isNotEmpty ?? false)
        ? vocab.kanji!.trim()
        : vocab.kana;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (item.newLevel != null)
                  Chip(
                    label: Text('Lv ${item.oldLevel} → ${item.newLevel}'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${vocab.kana} • ${vocab.romaji}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(vocab.meaning),
            if (item.reviewResult.wrongAnswers > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Sai ${item.reviewResult.wrongAnswers} lần',
                style: TextStyle(
                  color: context.appDanger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (item.nextReviewAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ôn tiếp: ${formatNextReview(item.nextReviewAt!)}',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
            if (item.message != null) ...[
              const SizedBox(height: 4),
              Text(
                item.message!,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
