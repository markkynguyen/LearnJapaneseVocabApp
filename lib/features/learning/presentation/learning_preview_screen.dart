import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/router/app_routes.dart';
import '../../vocab/presentation/widgets/pitch_accent_text.dart';
import '../domain/learning_models.dart';
import 'providers/learning_provider.dart';

class LearningPreviewScreen extends ConsumerStatefulWidget {
  const LearningPreviewScreen({
    required this.folderId,
    this.request = const LearningPreviewRequest(),
    super.key,
  });

  final int folderId;
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
                    itemBuilder: (context, index) => _LearningWordCard(
                      item: words[index],
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

class _LearningWordCard extends StatelessWidget {
  const _LearningWordCard({required this.item});

  final VocabWithProgress item;

  @override
  Widget build(BuildContext context) {
    final vocab = item.vocab;
    final colors = Theme.of(context).colorScheme;
    final hasKanji = vocab.kanji?.trim().isNotEmpty == true;
    final hasNote = vocab.note?.trim().isNotEmpty == true;
    final hasExample = vocab.example?.trim().isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Container(
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
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        vocab.meaning,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
                if (hasNote)
                  _LearningDetailSection(
                    icon: Icons.edit_note_rounded,
                    title: 'Ghi chú',
                    value: vocab.note!.trim(),
                  ),
                if (hasExample)
                  _LearningDetailSection(
                    icon: Icons.notes_rounded,
                    title: 'Ví dụ',
                    value: vocab.example!.trim(),
                  ),
                if (!hasNote && !hasExample) ...[
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'Đã sẵn sàng để luyện tập',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LearningDetailSection extends StatelessWidget {
  const _LearningDetailSection({
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

class _EmptyLearningState extends StatelessWidget {
  const _EmptyLearningState({required this.folderId});
  final int folderId;

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
