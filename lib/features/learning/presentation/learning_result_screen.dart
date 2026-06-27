import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../domain/learning_models.dart';

class LearningResultScreen extends ConsumerWidget {
  const LearningResultScreen({required this.summary, super.key});

  final LearningResultSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Kết quả học từ mới'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_stories_rounded, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        '${summary.passedWords.length}/${summary.words.length} từ đã học',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 6),
                      Text('${summary.failedWords.length} từ cần học lại'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ...summary.words.map(
                (word) => Card(
                  child: ListTile(
                    leading: Icon(
                      word.passed
                          ? Icons.check_circle_rounded
                          : Icons.replay_rounded,
                    ),
                    title: Text(
                      word.item.vocab.kanji?.trim().isNotEmpty == true
                          ? word.item.vocab.kanji!.trim()
                          : word.item.vocab.kana,
                    ),
                    subtitle: Text(
                      word.passed ? 'Đã chuyển lên Lv 1' : 'Giữ nguyên Lv 0',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => context.go(
                  AppRoutes.learningPreview(summary.folderId),
                  extra: LearningPreviewRequest(
                    excludeIds: summary.words
                        .map((word) => word.item.vocab.id)
                        .toList(),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Tiếp tục học từ mới'),
              ),
              if (summary.failedWords.isNotEmpty) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => context.go(
                    AppRoutes.learningPreview(summary.folderId),
                    extra: LearningPreviewRequest(
                      words:
                          summary.failedWords.map((word) => word.item).toList(),
                    ),
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Học lại từ chưa đạt'),
                ),
              ],
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.folderVocab(summary.folderId)),
                icon: const Icon(Icons.folder_rounded),
                label: const Text('Trở về bộ từ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
