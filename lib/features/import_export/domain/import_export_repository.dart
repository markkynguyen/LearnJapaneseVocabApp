import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/srs_constants.dart';
import '../../../core/database/app_database.dart';
import '../data/excel_vocab_exporter.dart';
import '../data/excel_vocab_parser.dart';
import 'excel_vocab_models.dart';

class ImportExportRepository {
  const ImportExportRepository({
    required VocabularyDao vocabularyDao,
    required FolderDao folderDao,
    required SrsProgressDao srsProgressDao,
    ExcelVocabParser? parser,
    ExcelVocabExporter? exporter,
  })  : _vocabularyDao = vocabularyDao,
        _folderDao = folderDao,
        _srsProgressDao = srsProgressDao,
        _parser = parser ?? const ExcelVocabParser(),
        _exporter = exporter ?? const ExcelVocabExporter();

  final VocabularyDao _vocabularyDao;
  final FolderDao _folderDao;
  final SrsProgressDao _srsProgressDao;
  final ExcelVocabParser _parser;
  final ExcelVocabExporter _exporter;

  Future<ExcelImportPreview?> pickAndPreview({
    required int folderId,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) {
      return null;
    }

    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final preview = _parser.parse(bytes: bytes, fileName: file.name);
    return _markDuplicates(preview, folderId);
  }

  Future<ExcelImportPreview?> pickAndPreviewMultipleFolders() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) {
      return null;
    }

    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    final preview = _parser.parse(
      bytes: bytes,
      fileName: file.name,
      requireFolder: true,
    );
    return _markDuplicatesByFolder(preview);
  }

  Future<ExcelImportResult> importRows({
    required int folderId,
    required ExcelImportPreview preview,
    required DuplicateStrategy duplicateStrategy,
  }) async {
    var inserted = 0;
    var updated = 0;
    var skipped = 0;
    var failed = preview.errorCount;

    final existing = await _existingByKana(folderId);
    for (final row in preview.rows.where((row) => row.isValid)) {
      final duplicate = existing[row.kana];
      if (duplicate != null && duplicateStrategy == DuplicateStrategy.skip) {
        skipped++;
        continue;
      }

      try {
        if (duplicate == null) {
          final vocabId = await _vocabularyDao.insertVocab(
            VocabularyCompanion.insert(
              folderId: folderId,
              kana: row.kana,
              romaji: row.romaji,
              meaning: row.meaning,
              kanji: Value(row.kanji),
              pitchAccent: Value(row.pitchAccent),
              example: Value(row.example),
              note: Value(row.note),
            ),
          );
          await _applyImportedProgress(vocabId, row);
          inserted++;
          final created = await _vocabularyDao.getVocabById(vocabId);
          if (created != null) {
            existing[row.kana] = created;
          }
        } else {
          await _vocabularyDao.updateVocab(
            VocabularyCompanion(
              id: Value(duplicate.vocab.id),
              folderId: Value(folderId),
              kana: Value(row.kana),
              romaji: Value(row.romaji),
              meaning: Value(row.meaning),
              kanji: Value(row.kanji),
              pitchAccent: Value(row.pitchAccent),
              example: Value(row.example),
              note: Value(row.note),
              audioPath: Value(duplicate.vocab.audioPath),
              isFavorite: Value(duplicate.vocab.isFavorite),
              createdAt: Value(duplicate.vocab.createdAt),
            ),
          );
          await _applyImportedProgress(duplicate.vocab.id, row);
          updated++;
          final refreshed =
              await _vocabularyDao.getVocabById(duplicate.vocab.id);
          if (refreshed != null) {
            existing[row.kana] = refreshed;
          }
        }
      } catch (_) {
        failed++;
      }
    }

    return ExcelImportResult(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
      failed: failed,
    );
  }

  Future<ExcelImportResult> importRowsByFolder({
    required ExcelImportPreview preview,
    required DuplicateStrategy duplicateStrategy,
  }) async {
    var inserted = 0;
    var updated = 0;
    var skipped = 0;
    var failed = preview.errorCount;
    var createdFolders = 0;

    final folderByName = await _folderByName();
    final existingByFolderId = <int, Map<String, VocabWithProgress>>{};

    for (final row in preview.rows.where((row) => row.isValid)) {
      final folderName = row.folderName?.trim();
      if (folderName == null || folderName.isEmpty) {
        failed++;
        continue;
      }

      try {
        final folder = await _ensureFolder(folderName, folderByName);
        if (!folderByName.containsKey(_normalizeFolderName(folderName))) {
          createdFolders++;
        }
        folderByName[_normalizeFolderName(folder.name)] = folder;

        final existing = existingByFolderId.putIfAbsent(
          folder.id,
          () => <String, VocabWithProgress>{},
        );
        if (existing.isEmpty) {
          existing.addAll(await _existingByKana(folder.id));
        }

        final duplicate = existing[row.kana];
        if (duplicate != null && duplicateStrategy == DuplicateStrategy.skip) {
          skipped++;
          continue;
        }

        if (duplicate == null) {
          final vocabId = await _vocabularyDao.insertVocab(
            VocabularyCompanion.insert(
              folderId: folder.id,
              kana: row.kana,
              romaji: row.romaji,
              meaning: row.meaning,
              kanji: Value(row.kanji),
              pitchAccent: Value(row.pitchAccent),
              example: Value(row.example),
              note: Value(row.note),
            ),
          );
          await _applyImportedProgress(vocabId, row);
          inserted++;
          final created = await _vocabularyDao.getVocabById(vocabId);
          if (created != null) {
            existing[row.kana] = created;
          }
        } else {
          await _vocabularyDao.updateVocab(
            VocabularyCompanion(
              id: Value(duplicate.vocab.id),
              folderId: Value(folder.id),
              kana: Value(row.kana),
              romaji: Value(row.romaji),
              meaning: Value(row.meaning),
              kanji: Value(row.kanji),
              pitchAccent: Value(row.pitchAccent),
              example: Value(row.example),
              note: Value(row.note),
              audioPath: Value(duplicate.vocab.audioPath),
              isFavorite: Value(duplicate.vocab.isFavorite),
              createdAt: Value(duplicate.vocab.createdAt),
            ),
          );
          await _applyImportedProgress(duplicate.vocab.id, row);
          updated++;
          final refreshed =
              await _vocabularyDao.getVocabById(duplicate.vocab.id);
          if (refreshed != null) {
            existing[row.kana] = refreshed;
          }
        }
      } catch (_) {
        failed++;
      }
    }

    return ExcelImportResult(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
      failed: failed,
      createdFolders: createdFolders,
    );
  }

  Future<String> exportFolder(int folderId) async {
    final folder = await _folderDao.getFolderById(folderId);
    if (folder == null) {
      throw StateError('Không tìm thấy folder để export.');
    }
    final items = await _srsProgressDao.watchProgressByFolder(folderId).first;
    return _writeAndShare(
      [
        ExportFolderBundle(folder: folder, items: items),
      ],
      'jvocab_${folder.name}_${_exportTimestamp()}.xlsx',
    );
  }

  Future<String> exportAll() async {
    final folders = await _folderDao.watchAllFolders().first;
    final bundles = <ExportFolderBundle>[];
    for (final folder in folders) {
      final items =
          await _srsProgressDao.watchProgressByFolder(folder.id).first;
      bundles.add(ExportFolderBundle(folder: folder, items: items));
    }
    return _writeAndShare(bundles, 'jvocab_backup_${_exportTimestamp()}.xlsx');
  }

  Future<String> exportTemplate() async {
    final directory = await getTemporaryDirectory();
    final path =
        p.join(directory.path, 'jvocab_template_${_exportTimestamp()}.xlsx');
    await File(path).writeAsBytes(_exporter.exportTemplate(), flush: true);
    await Share.shareXFiles([XFile(path)], text: 'Nana App Excel template');
    return path;
  }

  Future<String> _writeAndShare(
    List<ExportFolderBundle> bundles,
    String fileName,
  ) async {
    final bytes = _exporter.exportBundles(bundles);
    final directory = await getTemporaryDirectory();
    final sanitizedName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final path = p.join(directory.path, sanitizedName);
    await File(path).writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(path)], text: 'Nana App Excel backup');
    return path;
  }

  Future<ExcelImportPreview> _markDuplicates(
    ExcelImportPreview preview,
    int folderId,
  ) async {
    final existing = await _existingByKana(folderId);
    return ExcelImportPreview(
      fileName: preview.fileName,
      rows: [
        for (final row in preview.rows)
          row.copyWith(isDuplicate: existing.containsKey(row.kana)),
      ],
    );
  }

  Future<ExcelImportPreview> _markDuplicatesByFolder(
    ExcelImportPreview preview,
  ) async {
    final folderByName = await _folderByName();
    final existingByFolderId = <int, Map<String, VocabWithProgress>>{};
    final rows = <ExcelVocabRow>[];

    for (final row in preview.rows) {
      final folderName = row.folderName;
      final folder = folderName == null
          ? null
          : folderByName[_normalizeFolderName(folderName)];
      if (!row.isValid || folder == null) {
        rows.add(row);
        continue;
      }

      final existing =
          existingByFolderId[folder.id] ?? await _existingByKana(folder.id);
      existingByFolderId[folder.id] = existing;
      rows.add(row.copyWith(isDuplicate: existing.containsKey(row.kana)));
    }

    return ExcelImportPreview(fileName: preview.fileName, rows: rows);
  }

  Future<Map<String, VocabWithProgress>> _existingByKana(int folderId) async {
    final existing = await _vocabularyDao.searchVocab(folderId, '');
    return {
      for (final item in existing) item.vocab.kana: item,
    };
  }

  Future<Map<String, Folder>> _folderByName() async {
    final folders = await _folderDao.watchAllFolders().first;
    return {
      for (final folder in folders) _normalizeFolderName(folder.name): folder,
    };
  }

  Future<Folder> _ensureFolder(
    String folderName,
    Map<String, Folder> folderByName,
  ) async {
    final normalized = _normalizeFolderName(folderName);
    final existing = folderByName[normalized];
    if (existing != null) {
      return existing;
    }

    final folderId = await _folderDao.insertFolder(
      FoldersCompanion.insert(name: folderName.trim()),
    );
    final created = await _folderDao.getFolderById(folderId);
    if (created == null) {
      throw StateError('Không thể tạo folder $folderName.');
    }
    return created;
  }

  Future<void> _applyImportedProgress(int vocabId, ExcelVocabRow row) async {
    final level = row.level;
    final nextReview = row.nextReview;
    if (level == null && nextReview == null) {
      return;
    }

    final effectiveLevel = level ?? SrsConstants.unlearnedLevel;
    final intervalDays = SrsConstants.defaultIntervalForLevel(effectiveLevel);
    final effectiveNextReview = nextReview ??
        (effectiveLevel == SrsConstants.unlearnedLevel
            ? 0
            : DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await _srsProgressDao.updateProgressByVocabId(
      vocabId,
      SrsProgressCompanion(
        level: Value(effectiveLevel),
        intervalDays: Value(intervalDays),
        nextReviewAt: Value(effectiveNextReview),
      ),
    );
  }
}

String _normalizeFolderName(String value) => value.trim().toLowerCase();

String _exportTimestamp() {
  final now = DateTime.now();
  final year = now.year.toString().padLeft(4, '0');
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  final hour = now.hour.toString().padLeft(2, '0');
  final minute = now.minute.toString().padLeft(2, '0');
  return '$year$month${day}_$hour$minute';
}
