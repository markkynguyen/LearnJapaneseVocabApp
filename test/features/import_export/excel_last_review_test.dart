import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/import_export/data/excel_vocab_exporter.dart';
import 'package:jvocab/features/import_export/data/excel_vocab_parser.dart';
import 'package:jvocab/features/import_export/domain/excel_vocab_models.dart';

void main() {
  test('exported Excel keeps last_review and parser reads it back', () {
    const lastReview = 1770000000;
    final bytes = const ExcelVocabExporter().exportBundles(const [
      ExportFolderBundle(
        folder: Folder(
          id: 'folder-1',
          name: 'N5',
          color: '#6366F1',
          createdAt: 1,
        ),
        items: [
          VocabWithProgress(
            vocab: VocabularyEntry(
              id: 'vocab-1',
              folderId: 'folder-1',
              kana: 'たべる',
              romaji: 'taberu',
              meaning: 'ăn',
              isFavorite: false,
              createdAt: 1,
            ),
            progress: SrsProgressEntry(
              vocabId: 'vocab-1',
              level: 3,
              intervalDays: 2,
              nextReviewAt: 1780000000,
              correctCount: 4,
              wrongCount: 1,
              lastReviewedAt: lastReview,
            ),
          ),
        ],
      ),
    ]);

    final preview = const ExcelVocabParser().parse(
      bytes: bytes,
      fileName: 'backup.xlsx',
      requireFolder: true,
    );

    expect(preview.validCount, 1);
    expect(preview.rows.single.lastReview, lastReview);
    expect(preview.rows.single.folderName, 'N5');
  });
}
