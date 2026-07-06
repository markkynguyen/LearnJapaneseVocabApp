import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/cloud/cloud_store.dart';
import '../../../core/constants/srs_constants.dart';
import '../../../core/models/app_models.dart';
import '../data/excel_vocab_exporter.dart';
import '../data/excel_vocab_parser.dart';
import 'excel_vocab_models.dart';

class ImportExportRepository {
  const ImportExportRepository({
    required CloudStore store,
    ExcelVocabParser? parser,
    ExcelVocabExporter? exporter,
  })  : _store = store,
        _parser = parser ?? const ExcelVocabParser(),
        _exporter = exporter ?? const ExcelVocabExporter();

  final CloudStore _store;
  final ExcelVocabParser _parser;
  final ExcelVocabExporter _exporter;

  Future<ExcelImportPreview?> pickAndPreview({required String folderId}) async {
    final preview = await _pick(requireFolder: false);
    if (preview == null) return null;
    final existing = await _existingByKana(folderId);
    return ExcelImportPreview(
      fileName: preview.fileName,
      ignoredBlankRowCount: preview.ignoredBlankRowCount,
      rows: [
        for (final row in preview.rows)
          row.copyWith(isDuplicate: existing.containsKey(row.kana)),
      ],
    );
  }

  Future<ExcelImportPreview?> pickAndPreviewMultipleFolders() async {
    final preview = await _pick(requireFolder: true);
    if (preview == null) return null;
    final folders = await _store.getFolders();
    final byName = {
      for (final folder in folders) _normalize(folder.name): folder,
    };
    final cache = <String, Map<String, VocabWithProgress>>{};
    final rows = <ExcelVocabRow>[];
    for (final row in preview.rows) {
      final folder =
          row.folderName == null ? null : byName[_normalize(row.folderName!)];
      if (!row.isValid || folder == null) {
        rows.add(row);
        continue;
      }
      final existing = cache[folder.id] ?? await _existingByKana(folder.id);
      cache[folder.id] = existing;
      rows.add(row.copyWith(isDuplicate: existing.containsKey(row.kana)));
    }
    return ExcelImportPreview(
      fileName: preview.fileName,
      rows: rows,
      ignoredBlankRowCount: preview.ignoredBlankRowCount,
    );
  }

  Future<ExcelImportPreview?> _pick({required bool requireFolder}) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) return null;
    final bytes = file.bytes ?? await File(file.path!).readAsBytes();
    return _parser.parse(
      bytes: bytes,
      fileName: file.name,
      requireFolder: requireFolder,
    );
  }

  Future<ExcelImportResult> importRows({
    required String folderId,
    required ExcelImportPreview preview,
    required DuplicateStrategy duplicateStrategy,
  }) =>
      _importIntoFolder(
        folderId: folderId,
        rows: preview.rows,
        duplicateStrategy: duplicateStrategy,
        initialFailed: preview.errorCount,
      );

  Future<ExcelImportResult> importRowsByFolder({
    required ExcelImportPreview preview,
    required DuplicateStrategy duplicateStrategy,
  }) async {
    var inserted = 0;
    var updated = 0;
    var skipped = 0;
    var failed = preview.errorCount;
    var createdFolders = 0;
    final folders = await _store.getFolders();
    final byName = {
      for (final folder in folders) _normalize(folder.name): folder,
    };
    for (final group in _groupValidRows(preview.rows).entries) {
      final normalized = _normalize(group.key);
      var folder = byName[normalized];
      if (folder == null) {
        final id = await _store.createFolder(
          name: group.key.trim(),
          color: '#6366F1',
        );
        folder = await _store.getFolder(id);
        if (folder == null) {
          failed += group.value.length;
          continue;
        }
        byName[normalized] = folder;
        createdFolders++;
      }
      final result = await _importIntoFolder(
        folderId: folder.id,
        rows: group.value,
        duplicateStrategy: duplicateStrategy,
      );
      inserted += result.inserted;
      updated += result.updated;
      skipped += result.skipped;
      failed += result.failed;
    }
    return ExcelImportResult(
      inserted: inserted,
      updated: updated,
      skipped: skipped,
      failed: failed,
      createdFolders: createdFolders,
    );
  }

  Future<ExcelImportResult> _importIntoFolder({
    required String folderId,
    required Iterable<ExcelVocabRow> rows,
    required DuplicateStrategy duplicateStrategy,
    int initialFailed = 0,
  }) async {
    final validRows = rows.where((row) => row.isValid).toList();
    final result = await _store.importVocabulary(
      folderId: folderId,
      duplicateStrategy: duplicateStrategy.name,
      rows: [
        for (final row in validRows)
          {
            'kanji': row.kanji,
            'kana': row.kana,
            'romaji': row.romaji,
            'meaning': row.meaning,
            'pitch_accent': row.pitchAccent,
            'example': row.example,
            'note': row.note,
            if (row.level != null) 'level': row.level,
            if (row.level != null)
              'interval_days': SrsConstants.defaultIntervalForLevel(row.level!),
            if (row.nextReview != null)
              'next_review': secondsToCloudTimestamp(row.nextReview!),
            if (row.hasLastReviewColumn)
              'last_review': row.lastReview == null
                  ? ''
                  : secondsToCloudTimestamp(row.lastReview!),
          },
      ],
    );
    return ExcelImportResult(
      inserted: (result['inserted'] as num?)?.toInt() ?? 0,
      updated: (result['updated'] as num?)?.toInt() ?? 0,
      skipped: (result['skipped'] as num?)?.toInt() ?? 0,
      failed: initialFailed + ((result['failed'] as num?)?.toInt() ?? 0),
    );
  }

  Future<String> exportFolder(String folderId) async {
    final folder = await _store.getFolder(folderId);
    if (folder == null) throw StateError('Không tìm thấy bộ từ để export.');
    return _writeAndShare(
      [
        ExportFolderBundle(
          folder: folder,
          items: await _store.getVocabByFolder(folderId),
        ),
      ],
      'jvocab_${folder.name}_${_timestamp()}.xlsx',
    );
  }

  Future<String> exportAll() async {
    final bundles = <ExportFolderBundle>[];
    for (final folder in await _store.getFolders()) {
      bundles.add(
        ExportFolderBundle(
          folder: folder,
          items: await _store.getVocabByFolder(folder.id),
        ),
      );
    }
    return _writeAndShare(bundles, 'jvocab_backup_${_timestamp()}.xlsx');
  }

  Future<String> exportTemplate() async {
    final directory = await getTemporaryDirectory();
    final path = p.join(directory.path, 'jvocab_template_${_timestamp()}.xlsx');
    await File(path).writeAsBytes(_exporter.exportTemplate(), flush: true);
    await Share.shareXFiles([XFile(path)], text: 'Nana App Excel template');
    return path;
  }

  Future<String> _writeAndShare(
    List<ExportFolderBundle> bundles,
    String fileName,
  ) async {
    final directory = await getTemporaryDirectory();
    final safe = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final path = p.join(directory.path, safe);
    await File(path)
        .writeAsBytes(_exporter.exportBundles(bundles), flush: true);
    await Share.shareXFiles([XFile(path)], text: 'Nana App cloud backup');
    return path;
  }

  Future<Map<String, VocabWithProgress>> _existingByKana(
    String folderId,
  ) async =>
      {
        for (final item in await _store.getVocabByFolder(folderId))
          item.vocab.kana: item,
      };

  Map<String, List<ExcelVocabRow>> _groupValidRows(List<ExcelVocabRow> rows) {
    final result = <String, List<ExcelVocabRow>>{};
    for (final row in rows.where((row) => row.isValid)) {
      final folder = row.folderName?.trim();
      if (folder != null && folder.isNotEmpty) {
        result.putIfAbsent(folder, () => []).add(row);
      }
    }
    return result;
  }
}

String _normalize(String value) => value.trim().toLowerCase();
String _timestamp() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
}
