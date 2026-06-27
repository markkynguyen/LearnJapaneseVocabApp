import 'dart:async';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/srs/srs_engine.dart';

part 'vocab_list_provider.g.dart';

@riverpod
class VocabSearchQuery extends _$VocabSearchQuery {
  @override
  String build(int folderId) => '';

  void update(String value) {
    state = value;
  }
}

@riverpod
class VocabSort extends _$VocabSort {
  @override
  VocabSortMode build(int folderId) => VocabSortMode.newest;

  void update(VocabSortMode value) {
    state = value;
  }
}

@riverpod
Stream<List<VocabWithProgress>> vocabList(VocabListRef ref, int folderId) {
  final sortMode = ref.watch(vocabSortProvider(folderId));
  final searchQuery = ref.watch(vocabSearchQueryProvider(folderId));

  return ref.watch(vocabularyDaoProvider).watchVocabByFolder(
        folderId,
        sortMode: sortMode,
        searchQuery: searchQuery,
      );
}

@riverpod
Stream<List<VocabWithProgress>> favoriteVocabList(
  FavoriteVocabListRef ref,
  int folderId,
) {
  return ref.watch(vocabularyDaoProvider).watchFavoriteVocab(folderId);
}

@riverpod
Stream<bool> hasFavoriteVocab(HasFavoriteVocabRef ref, int folderId) {
  return ref.watch(vocabularyDaoProvider).hasFavorites(folderId);
}

@riverpod
Stream<LevelStats> folderLevelStats(FolderLevelStatsRef ref, int folderId) {
  return ref.watch(srsProgressDaoProvider).watchLevelStats(folderId: folderId);
}

final folderDueCountProvider = StreamProvider.autoDispose.family<int, int>((
  ref,
  folderId,
) {
  return ref
      .watch(srsProgressDaoProvider)
      .watchDueWords(folderId: folderId)
      .map((words) => words.length);
});

final folderUnlearnedCountProvider =
    StreamProvider.autoDispose.family<int, int>((ref, folderId) {
  return ref
      .watch(srsProgressDaoProvider)
      .watchLevelStats(folderId: folderId)
      .map((stats) => stats.totalWords - stats.learnedWords);
});

@riverpod
class VocabListController extends _$VocabListController {
  @override
  FutureOr<void> build() {}

  Future<void> toggleFavorite(int vocabId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vocabularyDaoProvider).toggleFavorite(vocabId),
    );
  }

  Future<void> deleteVocab(int vocabId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vocabularyDaoProvider).deleteVocab(vocabId),
    );
  }

  Future<void> manualMinus1(VocabWithProgress item) async {
    await _applySrsResult(
      item,
      ref.read(srsEngineProvider).manualMinus1(item.progress),
    );
  }

  Future<void> manualReset(VocabWithProgress item) async {
    await _applySrsResult(
      item,
      ref.read(srsEngineProvider).manualReset(item.progress),
    );
  }

  Future<void> _applySrsResult(VocabWithProgress item, SrsResult result) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(srsProgressDaoProvider).updateProgressByVocabId(
            item.vocab.id,
            SrsProgressCompanion(
              level: Value(result.newLevel),
              intervalDays: Value(result.newIntervalDays),
              nextReviewAt: Value(result.newNextReviewAt),
              lastReviewedAt: Value(
                DateTime.now().millisecondsSinceEpoch ~/ 1000,
              ),
            ),
          ),
    );
  }
}
