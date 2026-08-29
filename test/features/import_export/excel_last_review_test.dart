import 'package:excel/excel.dart';
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
              kanji: '何時',
              kana: 'なんじ',
              romaji: 'nanji',
              meaning: 'mấy giờ',
              ttsText: 'なんじ',
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
    expect(preview.rows.single.ttsText, 'なんじ');
    expect(preview.rows.single.lastReview, lastReview);
    expect(preview.rows.single.folderName, 'N5');
  });

  test('export template includes tts_text after pitch_accent', () {
    final bytes = const ExcelVocabExporter().exportTemplate();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables['jvocab']!;
    final headers = sheet.rows.first
        .map((cell) => (cell?.value as TextCellValue).value.text)
        .toList();

    expect(headers, excelVocabHeaders);
    expect(
      headers.indexOf('tts_text'),
      headers.indexOf('pitch_accent') + 1,
    );
  });
}
