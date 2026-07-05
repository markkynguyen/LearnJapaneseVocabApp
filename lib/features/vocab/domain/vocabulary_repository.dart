import '../../../core/cloud/cloud_store.dart';
import '../../../core/models/app_models.dart';

class VocabularyRepository {
  const VocabularyRepository(this._store);
  final CloudStore _store;

  Future<VocabWithProgress?> getVocabById(String id) => _store.getVocab(id);

  Future<String> createVocab({
    required String folderId,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? example,
    String? note,
  }) =>
      _store.createVocab(
        folderId: folderId,
        kana: kana.trim(),
        romaji: romaji.trim(),
        meaning: meaning.trim(),
        kanji: _emptyToNull(kanji),
        pitchAccent: _emptyToNull(pitchAccent),
        example: _emptyToNull(example),
        note: _emptyToNull(note),
      );

  Future<void> updateVocab({
    required VocabularyEntry existing,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? example,
    String? note,
  }) =>
      _store.updateVocab(
        id: existing.id,
        kana: kana.trim(),
        romaji: romaji.trim(),
        meaning: meaning.trim(),
        kanji: _emptyToNull(kanji),
        pitchAccent: _emptyToNull(pitchAccent),
        example: _emptyToNull(example),
        note: _emptyToNull(note),
      );

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
