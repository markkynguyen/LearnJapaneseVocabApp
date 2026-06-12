import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/vocabulary_repository.dart';

part 'vocab_form_provider.g.dart';

@riverpod
VocabularyRepository vocabularyRepository(VocabularyRepositoryRef ref) {
  return VocabularyRepository(ref.watch(vocabularyDaoProvider));
}

@riverpod
Future<VocabWithProgress?> vocabFormItem(VocabFormItemRef ref, int vocabId) {
  return ref.watch(vocabularyRepositoryProvider).getVocabById(vocabId);
}

@riverpod
class VocabFormController extends _$VocabFormController {
  @override
  FutureOr<void> build() {}

  Future<void> create({
    required int folderId,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? example,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vocabularyRepositoryProvider).createVocab(
            folderId: folderId,
            kana: kana,
            romaji: romaji,
            meaning: meaning,
            kanji: kanji,
            pitchAccent: pitchAccent,
            example: example,
            note: note,
          ),
    );
  }

  Future<void> updateExisting({
    required VocabularyEntry existing,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? example,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(vocabularyRepositoryProvider).updateVocab(
            existing: existing,
            kana: kana,
            romaji: romaji,
            meaning: meaning,
            kanji: kanji,
            pitchAccent: pitchAccent,
            example: example,
            note: note,
          ),
    );
  }
}
