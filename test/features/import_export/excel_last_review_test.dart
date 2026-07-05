import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/database/app_database.dart';
import 'package:jvocab/features/import_export/data/excel_vocab_exporter.dart';
import 'package:jvocab/features/import_export/data/excel_vocab_parser.dart';
import 'package:jvocab/features/import_export/domain/excel_vocab_models.dart';
import 'package:jvocab/features/import_export/domain/import_export_repository.dart';
import 'package:path/path.dart' as p;

void main() {
  test('exported Excel keeps last_review and parser reads it back', () {
    const lastReview = 1770000000;
    final bytes = const ExcelVocabExporter().exportBundles(const [
      ExportFolderBundle(
        folder: Folder(
          id: 1,
          name: 'N5',
          color: '#6366F1',
          createdAt: 1,
        ),
        items: [
          VocabWithProgress(
            vocab: VocabularyEntry(
              id: 1,
              folderId: 1,
              kana: 'たべる',
              romaji: 'taberu',
              meaning: 'ăn',
              isFavorite: false,
              createdAt: 1,
            ),
            progress: SrsProgressEntry(
              id: 1,
              vocabId: 1,
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

  group('import last_review', skip: _sqliteSkipReason, () {
    late AppDatabase database;
    late ImportExportRepository repository;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      repository = ImportExportRepository(
        vocabularyDao: database.vocabularyDao,
        folderDao: database.folderDao,
        srsProgressDao: database.srsProgressDao,
      );
    });

    tearDown(() => database.close());

    test('writes last_review into SRS progress', () async {
      final folderId = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'N5'),
      );

      final result = await repository.importRows(
        folderId: folderId,
        preview: const ExcelImportPreview(
          fileName: 'backup.xlsx',
          rows: [
            ExcelVocabRow(
              rowNumber: 2,
              kana: 'たべる',
              romaji: 'taberu',
              meaning: 'ăn',
              level: 3,
              nextReview: 1780000000,
              lastReview: 1770000000,
              hasLastReviewColumn: true,
            ),
          ],
        ),
        duplicateStrategy: DuplicateStrategy.overwrite,
      );

      final item =
          (await database.vocabularyDao.searchVocab(folderId, '')).single;
      final progress =
          await database.srsProgressDao.getProgressByVocabId(item.vocab.id);

      expect(result.inserted, 1);
      expect(progress!.lastReviewedAt, 1770000000);
    });

    test('legacy rows do not clear an existing last review', () async {
      final folderId = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'N5'),
      );
      final vocabId = await database.vocabularyDao.insertVocab(
        VocabularyCompanion.insert(
          folderId: folderId,
          kana: 'たべる',
          romaji: 'taberu',
          meaning: 'ăn',
        ),
      );
      await database.srsProgressDao.updateProgressByVocabId(
        vocabId,
        const SrsProgressCompanion(lastReviewedAt: Value(1760000000)),
      );

      await repository.importRows(
        folderId: folderId,
        preview: const ExcelImportPreview(
          fileName: 'legacy.xlsx',
          rows: [
            ExcelVocabRow(
              rowNumber: 2,
              kana: 'たべる',
              romaji: 'taberu',
              meaning: 'ăn',
              level: 2,
              nextReview: 1780000000,
            ),
          ],
        ),
        duplicateStrategy: DuplicateStrategy.overwrite,
      );

      final progress =
          await database.srsProgressDao.getProgressByVocabId(vocabId);
      expect(progress!.lastReviewedAt, 1760000000);
    });
  });
}

String? get _sqliteSkipReason {
  if (!Platform.isWindows) {
    return null;
  }

  final path = Platform.environment['PATH'] ?? '';
  final hasSqliteDll = path
      .split(';')
      .where((entry) => entry.trim().isNotEmpty)
      .any((entry) => File(p.join(entry, 'sqlite3.dll')).existsSync());

  if (hasSqliteDll || File('sqlite3.dll').existsSync()) {
    return null;
  }
  return 'sqlite3.dll is not available to the Dart VM on Windows.';
}
