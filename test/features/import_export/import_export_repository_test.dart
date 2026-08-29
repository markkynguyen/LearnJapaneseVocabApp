import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/features/import_export/domain/excel_vocab_models.dart';
import 'package:jvocab/features/import_export/domain/import_export_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('import rows sends tts_text to cloud rpc payload', () async {
    final store = _FakeImportStore();
    final repository = ImportExportRepository(store: store);

    await repository.importRows(
      folderId: 'folder-1',
      preview: const ExcelImportPreview(
        fileName: 'sample.xlsx',
        rows: [
          ExcelVocabRow(
            rowNumber: 2,
            kanji: '何時',
            kana: 'なんじ',
            romaji: 'nanji',
            meaning: 'mấy giờ',
            ttsText: 'なんじ',
            hasTtsTextColumn: true,
          ),
        ],
      ),
      duplicateStrategy: DuplicateStrategy.overwrite,
    );

    expect(store.folderId, 'folder-1');
    expect(store.duplicateStrategy, 'overwrite');
    expect(store.rows.single['tts_text'], 'なんじ');
  });

  test('import rows omit tts_text when legacy file has no tts_text column',
      () async {
    final store = _FakeImportStore();
    final repository = ImportExportRepository(store: store);

    await repository.importRows(
      folderId: 'folder-1',
      preview: const ExcelImportPreview(
        fileName: 'legacy.xlsx',
        rows: [
          ExcelVocabRow(
            rowNumber: 2,
            kanji: '何時',
            kana: 'なんじ',
            romaji: 'nanji',
            meaning: 'mấy giờ',
          ),
        ],
      ),
      duplicateStrategy: DuplicateStrategy.overwrite,
    );

    expect(store.rows.single.containsKey('tts_text'), isFalse);
  });
}

class _FakeImportStore extends CloudStore {
  _FakeImportStore()
      : super(
          SupabaseClient(
            'http://localhost',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  String? folderId;
  String? duplicateStrategy;
  List<Map<String, dynamic>> rows = const [];

  @override
  Future<Map<String, dynamic>> importVocabulary({
    required String folderId,
    required List<Map<String, dynamic>> rows,
    required String duplicateStrategy,
  }) async {
    this.folderId = folderId;
    this.rows = rows;
    this.duplicateStrategy = duplicateStrategy;
    return {
      'inserted': rows.length,
      'updated': 0,
      'skipped': 0,
      'failed': 0,
    };
  }
}
