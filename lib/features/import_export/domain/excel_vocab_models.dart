import '../../../core/database/app_database.dart';

const excelVocabHeaders = [
  'kanji',
  'kana',
  'romaji',
  'meaning',
  'pitch_accent',
  'example',
  'note',
  'level',
  'next_review',
];

enum DuplicateStrategy {
  skip,
  overwrite,
}

enum ExcelImportMode {
  singleFolder,
  multipleFolders,
}

class ExcelVocabRow {
  const ExcelVocabRow({
    required this.rowNumber,
    required this.kana,
    required this.romaji,
    required this.meaning,
    this.kanji,
    this.pitchAccent,
    this.example,
    this.note,
    this.level,
    this.nextReview,
    this.folderName,
    this.error,
    this.isDuplicate = false,
  });

  final int rowNumber;
  final String kana;
  final String romaji;
  final String meaning;
  final String? kanji;
  final String? pitchAccent;
  final String? example;
  final String? note;
  final int? level;
  final int? nextReview;
  final String? folderName;
  final String? error;
  final bool isDuplicate;

  bool get isValid => error == null;

  ExcelVocabRow copyWith({
    String? error,
    bool? isDuplicate,
  }) {
    return ExcelVocabRow(
      rowNumber: rowNumber,
      kana: kana,
      romaji: romaji,
      meaning: meaning,
      kanji: kanji,
      pitchAccent: pitchAccent,
      example: example,
      note: note,
      level: level,
      nextReview: nextReview,
      folderName: folderName,
      error: error ?? this.error,
      isDuplicate: isDuplicate ?? this.isDuplicate,
    );
  }
}

class ExcelImportPreview {
  const ExcelImportPreview({
    required this.fileName,
    required this.rows,
  });

  final String fileName;
  final List<ExcelVocabRow> rows;

  int get validCount => rows.where((row) => row.isValid).length;
  int get errorCount => rows.where((row) => !row.isValid).length;
  int get duplicateCount => rows.where((row) => row.isDuplicate).length;
}

class ExcelImportResult {
  const ExcelImportResult({
    required this.inserted,
    required this.updated,
    required this.skipped,
    required this.failed,
    this.createdFolders = 0,
  });

  final int inserted;
  final int updated;
  final int skipped;
  final int failed;
  final int createdFolders;
}

class ExportFolderBundle {
  const ExportFolderBundle({
    required this.folder,
    required this.items,
  });

  final Folder folder;
  final List<VocabWithProgress> items;
}
