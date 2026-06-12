import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class VocabularyRepository {
  const VocabularyRepository(this._vocabularyDao);

  final VocabularyDao _vocabularyDao;

  Future<VocabWithProgress?> getVocabById(int id) {
    return _vocabularyDao.getVocabById(id);
  }

  Future<int> createVocab({
    required int folderId,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? example,
    String? note,
  }) {
    return _vocabularyDao.insertVocab(
      VocabularyCompanion.insert(
        folderId: folderId,
        kana: kana.trim(),
        romaji: romaji.trim(),
        meaning: meaning.trim(),
        kanji: Value(_emptyToNull(kanji)),
        pitchAccent: Value(_emptyToNull(pitchAccent)),
        example: Value(_emptyToNull(example)),
        note: Value(_emptyToNull(note)),
      ),
    );
  }

  Future<bool> updateVocab({
    required VocabularyEntry existing,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? example,
    String? note,
  }) {
    return _vocabularyDao.updateVocab(
      VocabularyCompanion(
        id: Value(existing.id),
        folderId: Value(existing.folderId),
        kana: Value(kana.trim()),
        romaji: Value(romaji.trim()),
        meaning: Value(meaning.trim()),
        kanji: Value(_emptyToNull(kanji)),
        pitchAccent: Value(_emptyToNull(pitchAccent)),
        example: Value(_emptyToNull(example)),
        note: Value(_emptyToNull(note)),
        audioPath: Value(existing.audioPath),
        isFavorite: Value(existing.isFavorite),
        createdAt: Value(existing.createdAt),
      ),
    );
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
