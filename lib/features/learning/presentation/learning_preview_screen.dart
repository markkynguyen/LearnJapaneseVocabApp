import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/models/app_models.dart';
import '../../../core/router/app_routes.dart';
import '../../vocab/presentation/widgets/vocabulary_study_card.dart';
import '../domain/learning_models.dart';
import 'providers/learning_provider.dart';

class LearningPreviewScreen extends ConsumerStatefulWidget {
  const LearningPreviewScreen({
    required this.folderId,
    this.request = const LearningPreviewRequest(),
    super.key,
  });

  final String folderId;
  final LearningPreviewRequest request;

  @override
  ConsumerState<LearningPreviewScreen> createState() =>
      _LearningPreviewScreenState();
}

class _LearningPreviewScreenState extends ConsumerState<LearningPreviewScreen> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final controller = ref.read(learningControllerProvider.notifier);
    final words = widget.request.words;
    if (words != null) {
      await controller.startWithWords(
        folderId: widget.folderId,
        words: words,
      );
    } else {
      await controller.start(
        folderId: widget.folderId,
        excludeIds: widget.request.excludeIds,
      );
    }
    if (!mounted) {
      return;
    }
    final loadedWords = ref.read(learningControllerProvider).valueOrNull?.words;
    if (loadedWords?.isNotEmpty == true) {
      _speak(loadedWords!.first.vocab);
    }
  }

  void _speak(VocabularyEntry vocab) {
    ref.read(audioServiceProvider).speak(vocab);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(learningControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Học từ mới'),
        leading: IconButton(
          tooltip: 'Trở về bộ từ',
          onPressed: () => context.go(AppRoutes.folderVocab(widget.folderId)),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: session.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('Không thể tải: $error')),
          data: (state) {
            final words = state?.words ?? const [];
            if (words.isEmpty) {
              return _EmptyLearningState(folderId: widget.folderId);
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Từ mới ${_index + 1}/${words.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${words.length} từ trong phiên học',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Phát âm',
                        onPressed: () => _speak(words[_index].vocab),
                        icon: const Icon(Icons.volume_up_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: (_index + 1) / words.length,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.28),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: words.length,
                    onPageChanged: (value) {
                      setState(() => _index = value);
                      _speak(words[value].vocab);
                    },
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                      child: VocabularyStudyCard(
                        vocab: words[index].vocab,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _index == 0
                              ? null
                              : () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                  ),
                          icon: const Icon(Icons.chevron_left_rounded),
                          label: const Text('Trước'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _index == words.length - 1
                              ? () => context.go(AppRoutes.learningSession)
                              : () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOut,
                                  ),
                          icon: Icon(
                            _index == words.length - 1
                                ? Icons.play_arrow_rounded
                                : Icons.chevron_right_rounded,
                          ),
                          label: Text(
                            _index == words.length - 1
                                ? 'Bắt đầu quiz'
                                : 'Tiếp',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyLearningState extends StatelessWidget {
  const _EmptyLearningState({required this.folderId});
  final String folderId;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 48),
              const SizedBox(height: 12),
              const Text('Không còn từ mới trong bộ này.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.go(AppRoutes.folderVocab(folderId)),
                child: const Text('Trở về bộ từ'),
              ),
            ],
          ),
        ),
      );
}
