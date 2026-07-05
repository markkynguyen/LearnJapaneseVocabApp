import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/models/app_models.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/presentation/providers/settings_provider.dart';
import 'providers/flashcard_provider.dart';
import 'widgets/pitch_accent_text.dart';

class FlashcardScreen extends ConsumerWidget {
  const FlashcardScreen({
    required this.folderId,
    this.folderName,
    super.key,
  });

  final String folderId;
  final String? folderName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(flashcardDeckProvider(folderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            tooltip: 'Đảo thứ tự',
            onPressed: () {
              ref
                  .read(flashcardDeckProvider(folderId).notifier)
                  .toggleShuffle();
            },
            icon: const Icon(Icons.shuffle_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: deck.when(
          data: (state) => _FlashcardContent(
            folderId: folderId,
            folderName: folderName,
            state: state,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Không thể tải flashcards: $error',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appDanger),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FlashcardContent extends ConsumerWidget {
  const _FlashcardContent({
    required this.folderId,
    required this.folderName,
    required this.state,
  });

  final String folderId;
  final String? folderName;
  final FlashcardDeckState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.items.isEmpty) {
      return const _EmptyFlashcardState();
    }

    final current = state.current!;
    final colors = Theme.of(context).colorScheme;
    final settings = ref.watch(appSettingsProvider).valueOrNull;
    final showKana = settings?.flashcardShowKana ?? true;
    final showRomaji = settings?.flashcardShowRomaji ?? true;

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
                      folderName ?? 'Bộ từ hiện tại',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.displayIndex}/${state.items.length}'
                      '${state.isShuffled ? ' • Đang đảo thẻ' : ''}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Kana'),
                selected: showKana,
                onSelected: (value) => ref
                    .read(settingsControllerProvider.notifier)
                    .updateFlashcardShowKana(value),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Romaji'),
                selected: showRomaji,
                onSelected: (value) => ref
                    .read(settingsControllerProvider.notifier)
                    .updateFlashcardShowRomaji(value),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Phát âm',
                onPressed: () {
                  ref.read(audioServiceProvider).speak(current.vocab);
                },
                icon: const Icon(Icons.volume_up_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: state.displayIndex / state.items.length,
              backgroundColor: colors.outline.withValues(alpha: 0.28),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
            child: _FlipCard(
              vocab: current.vocab,
              isBackVisible: state.isBackVisible,
              showKana: showKana,
              showRomaji: showRomaji,
              onTap: () {
                ref.read(flashcardDeckProvider(folderId).notifier).flip();
              },
              onSwipeLeft: state.hasNext
                  ? () =>
                      ref.read(flashcardDeckProvider(folderId).notifier).next()
                  : null,
              onSwipeRight: state.hasPrevious
                  ? () => ref
                      .read(flashcardDeckProvider(folderId).notifier)
                      .previous()
                  : null,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.hasPrevious
                      ? () => ref
                          .read(flashcardDeckProvider(folderId).notifier)
                          .previous()
                      : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  label: const Text('Trước'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: state.isBackVisible ? 'Xem mặt trước' : 'Lật thẻ',
                onPressed: () {
                  ref.read(flashcardDeckProvider(folderId).notifier).flip();
                },
                icon: const Icon(Icons.flip_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: state.hasNext
                      ? () => ref
                          .read(flashcardDeckProvider(folderId).notifier)
                          .next()
                      : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  label: const Text('Tiếp'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({
    required this.vocab,
    required this.isBackVisible,
    required this.showKana,
    required this.showRomaji,
    required this.onTap,
    required this.onSwipeLeft,
    required this.onSwipeRight,
  });

  final VocabularyEntry vocab;
  final bool isBackVisible;
  final bool showKana;
  final bool showRomaji;
  final VoidCallback onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: isBackVisible ? 0 : math.pi,
        end: isBackVisible ? math.pi : 0,
      ),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final showBack = value > math.pi / 2;
        return GestureDetector(
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -180) {
              onSwipeLeft?.call();
            } else if (velocity > 180) {
              onSwipeRight?.call();
            }
          },
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(value),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(showBack ? math.pi : 0),
              child: _FlashcardSurface(
                onTap: onTap,
                child: showBack
                    ? _FlashcardBack(vocab: vocab)
                    : _FlashcardFront(
                        vocab: vocab,
                        showKana: showKana,
                        showRomaji: showRomaji,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FlashcardSurface extends StatelessWidget {
  const _FlashcardSurface({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
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
          child: child,
        ),
      ),
    );
  }
}

class _FlashcardFront extends StatelessWidget {
  const _FlashcardFront({
    required this.vocab,
    required this.showKana,
    required this.showRomaji,
  });

  final VocabularyEntry vocab;
  final bool showKana;
  final bool showRomaji;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasKanji = vocab.kanji?.trim().isNotEmpty ?? false;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.style_rounded,
          color: colors.primary,
          size: 36,
        ),
        const SizedBox(height: 22),
        if (hasKanji)
          Text(
            vocab.kanji!.trim(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
          )
        else
          Center(
            child: PitchAccentText(
              kana: vocab.kana,
              pattern: vocab.pitchAccent,
              fontSize: 36,
            ),
          ),
        if (showKana && hasKanji) ...[
          const SizedBox(height: 16),
          Center(
            child: PitchAccentText(
              kana: vocab.kana,
              pattern: vocab.pitchAccent,
              fontSize: 22,
            ),
          ),
        ],
        if (showRomaji) ...[
          const SizedBox(height: 8),
          Text(
            vocab.romaji,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
        const SizedBox(height: 28),
        Text(
          'Chạm để xem nghĩa',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FlashcardBack extends StatelessWidget {
  const _FlashcardBack({required this.vocab});

  final VocabularyEntry vocab;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primary.withValues(alpha: 0.25)),
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
                        color: colors.onSurface,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
          ),
          if (_hasText(vocab.note))
            _BackSection(
              icon: Icons.edit_note_rounded,
              title: 'Ghi chú',
              child: Text(
                vocab.note!.trim(),
                style: const TextStyle(height: 1.45),
              ),
            ),
          if (_hasText(vocab.example))
            _BackSection(
              icon: Icons.notes_rounded,
              title: 'Ví dụ',
              child: Text(
                vocab.example!.trim(),
                style: const TextStyle(height: 1.45),
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Chạm để quay lại mặt trước',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasText(String? value) => value?.trim().isNotEmpty ?? false;
}

class _BackSection extends StatelessWidget {
  const _BackSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

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
          child,
        ],
      ),
    );
  }
}

class _EmptyFlashcardState extends StatelessWidget {
  const _EmptyFlashcardState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.style_rounded,
              color: colors.onSurfaceVariant,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có thẻ để học',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thêm từ vựng vào bộ này trước khi mở flashcards.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
