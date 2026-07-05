import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cloud/cloud_store.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/srs/srs_engine.dart';

part 'vocab_list_provider.g.dart';

@riverpod
class VocabSearchQuery extends _$VocabSearchQuery {
  @override
  String build(String folderId) => '';
  void update(String value) => state = value;
}

@riverpod
class VocabSort extends _$VocabSort {
  @override
  VocabSortMode build(String folderId) => VocabSortMode.newest;
  void update(VocabSortMode value) => state = value;
}

@riverpod
Future<List<VocabWithProgress>> vocabList(
  VocabListRef ref,
  String folderId,
) =>
    ref.watch(cloudStoreProvider).getVocabByFolder(
          folderId,
          sortMode: ref.watch(vocabSortProvider(folderId)),
          searchQuery: ref.watch(vocabSearchQueryProvider(folderId)),
        );

@riverpod
Future<List<VocabWithProgress>> favoriteVocabList(
  FavoriteVocabListRef ref,
  String folderId,
) =>
    ref
        .watch(cloudStoreProvider)
        .getVocabByFolder(folderId, favoritesOnly: true);

@riverpod
Future<bool> hasFavoriteVocab(HasFavoriteVocabRef ref, String folderId) async =>
    (await ref
            .watch(cloudStoreProvider)
            .getVocabByFolder(folderId, favoritesOnly: true))
        .isNotEmpty;

@riverpod
Future<LevelStats> folderLevelStats(
  FolderLevelStatsRef ref,
  String folderId,
) =>
    ref.watch(cloudStoreProvider).getLevelStats(folderId: folderId);

final folderDueCountProvider = FutureProvider.autoDispose.family<int, String>(
  (ref, folderId) =>
      ref.watch(cloudStoreProvider).getDueCount(folderId: folderId),
);

final folderUnlearnedCountProvider =
    FutureProvider.autoDispose.family<int, String>((ref, folderId) async {
  final stats =
      await ref.watch(cloudStoreProvider).getLevelStats(folderId: folderId);
  return stats.totalWords - stats.learnedWords;
});

@riverpod
class VocabListController extends _$VocabListController {
  @override
  FutureOr<void> build() {}

  Future<void> toggleFavorite(VocabWithProgress item) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(cloudStoreProvider).toggleFavorite(item.vocab),
    );
    _invalidate(item.vocab.folderId);
  }

  Future<void> deleteVocab(VocabularyEntry vocab) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(cloudStoreProvider).deleteVocab(vocab.id),
    );
    _invalidate(vocab.folderId);
  }

  Future<void> manualMinus1(VocabWithProgress item) => _applySrsResult(
        item,
        ref.read(srsEngineProvider).manualMinus1(item.progress),
      );

  Future<void> manualReset(VocabWithProgress item) => _applySrsResult(
        item,
        ref.read(srsEngineProvider).manualReset(item.progress),
      );

  Future<void> _applySrsResult(VocabWithProgress item, SrsResult result) async {
    state = const AsyncLoading();
    final next = item.progress.copyWith(
      level: result.newLevel,
      intervalDays: result.newIntervalDays,
      nextReviewAt: result.newNextReviewAt,
      lastReviewedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    state = await AsyncValue.guard(
      () => ref.read(cloudStoreProvider).updateProgress(next),
    );
    _invalidate(item.vocab.folderId);
  }

  void _invalidate(String folderId) {
    if (state.hasError) return;
    ref
      ..invalidate(vocabListProvider(folderId))
      ..invalidate(favoriteVocabListProvider(folderId))
      ..invalidate(hasFavoriteVocabProvider(folderId))
      ..invalidate(folderLevelStatsProvider(folderId))
      ..invalidate(folderDueCountProvider(folderId));
  }
}
