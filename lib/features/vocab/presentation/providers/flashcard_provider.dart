import 'dart:async';
import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';

part 'flashcard_provider.g.dart';

class FlashcardDeckState {
  const FlashcardDeckState({
    required this.items,
    required this.currentIndex,
    required this.isBackVisible,
    required this.isShuffled,
  });

  final List<VocabWithProgress> items;
  final int currentIndex;
  final bool isBackVisible;
  final bool isShuffled;

  VocabWithProgress? get current {
    if (items.isEmpty) {
      return null;
    }
    return items[currentIndex.clamp(0, items.length - 1)];
  }

  bool get hasPrevious => currentIndex > 0;
  bool get hasNext => currentIndex < items.length - 1;

  int get displayIndex {
    if (items.isEmpty) {
      return 0;
    }
    return currentIndex + 1;
  }

  FlashcardDeckState copyWith({
    List<VocabWithProgress>? items,
    int? currentIndex,
    bool? isBackVisible,
    bool? isShuffled,
  }) {
    return FlashcardDeckState(
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      isBackVisible: isBackVisible ?? this.isBackVisible,
      isShuffled: isShuffled ?? this.isShuffled,
    );
  }
}

@riverpod
Stream<List<VocabWithProgress>> flashcardVocabulary(
  FlashcardVocabularyRef ref,
  int folderId,
) {
  return ref.watch(vocabularyDaoProvider).watchVocabByFolder(
        folderId,
        sortMode: VocabSortMode.newest,
      );
}

@riverpod
class FlashcardDeck extends _$FlashcardDeck {
  @override
  FutureOr<FlashcardDeckState> build(int folderId) async {
    final items = await ref.watch(flashcardVocabularyProvider(folderId).future);
    return FlashcardDeckState(
      items: items,
      currentIndex: 0,
      isBackVisible: false,
      isShuffled: false,
    );
  }

  void flip() {
    final current = state.valueOrNull;
    if (current == null || current.items.isEmpty) {
      return;
    }

    state = AsyncData(
      current.copyWith(isBackVisible: !current.isBackVisible),
    );
  }

  void next() {
    final current = state.valueOrNull;
    if (current == null || !current.hasNext) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        currentIndex: current.currentIndex + 1,
        isBackVisible: false,
      ),
    );
  }

  void previous() {
    final current = state.valueOrNull;
    if (current == null || !current.hasPrevious) {
      return;
    }

    state = AsyncData(
      current.copyWith(
        currentIndex: current.currentIndex - 1,
        isBackVisible: false,
      ),
    );
  }

  void toggleShuffle() {
    final current = state.valueOrNull;
    if (current == null || current.items.length < 2) {
      return;
    }

    final nextItems = [...current.items];
    if (current.isShuffled) {
      nextItems.sort((a, b) => b.vocab.createdAt.compareTo(a.vocab.createdAt));
    } else {
      nextItems.shuffle(Random());
    }

    state = AsyncData(
      current.copyWith(
        items: nextItems,
        currentIndex: 0,
        isBackVisible: false,
        isShuffled: !current.isShuffled,
      ),
    );
  }
}
