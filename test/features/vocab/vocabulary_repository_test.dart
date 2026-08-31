import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/vocab/domain/vocabulary_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('create and update pass trimmed tts text to cloud store', () async {
    final store = _FakeVocabularyStore();
    final repository = VocabularyRepository(store);

    await repository.createVocab(
      folderId: 'folder-1',
      kanji: '何時',
      kana: 'なんじ',
      romaji: 'nanji',
      meaning: 'mấy giờ',
      ttsText: ' なんじ ',
    );
    await repository.updateVocab(
      existing: const VocabularyEntry(
        id: 'vocab-1',
        folderId: 'folder-1',
        kana: 'なんじ',
        romaji: 'nanji',
        meaning: 'mấy giờ',
        isFavorite: false,
        createdAt: 0,
      ),
      kanji: '何時',
      kana: 'なんじ',
      romaji: 'nanji',
      meaning: 'mấy giờ',
      ttsText: '   ',
    );

    expect(store.createdTtsText, 'なんじ');
    expect(store.updatedTtsText, isNull);
  });

  test('updateNote only sends a normalized note value', () async {
    final store = _FakeVocabularyStore();
    final repository = VocabularyRepository(store);

    await repository.updateNote(vocabId: 'vocab-1', note: '  Mẹo nhớ  ');
    expect(store.updatedNoteId, 'vocab-1');
    expect(store.updatedNote, 'Mẹo nhớ');

    await repository.updateNote(vocabId: 'vocab-1', note: '   ');
    expect(store.updatedNote, isNull);
  });
}

class _FakeVocabularyStore extends CloudStore {
  _FakeVocabularyStore()
      : super(
          SupabaseClient(
            'http://localhost',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  String? createdTtsText;
  String? updatedTtsText;
  String? updatedNoteId;
  String? updatedNote;

  @override
  Future<String> createVocab({
    required String folderId,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? ttsText,
    String? example,
    String? note,
  }) async {
    createdTtsText = ttsText;
    return 'vocab-1';
  }

  @override
  Future<void> updateVocab({
    required String id,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? ttsText,
    String? example,
    String? note,
  }) async {
    updatedTtsText = ttsText;
  }

  @override
  Future<void> updateVocabNote({
    required String id,
    required String? note,
  }) async {
    updatedNoteId = id;
    updatedNote = note;
  }
}
