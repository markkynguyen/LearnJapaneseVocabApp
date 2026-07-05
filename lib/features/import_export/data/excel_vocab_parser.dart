import 'package:excel/excel.dart';

import '../../../core/pitch_accent/pitch_accent_utils.dart';
import '../domain/excel_vocab_models.dart';

class ExcelVocabParser {
  const ExcelVocabParser();

  ExcelImportPreview parse({
    required List<int> bytes,
    required String fileName,
    bool requireFolder = false,
  }) {
    final excel = Excel.decodeBytes(bytes);
    final sheetName = excel.tables.keys.firstOrNull;
    if (sheetName == null) {
      return ExcelImportPreview(
        fileName: fileName,
        rows: const [
          ExcelVocabRow(
            rowNumber: 1,
            kana: '',
            romaji: '',
            meaning: '',
            error: 'File không có sheet dữ liệu.',
          ),
        ],
      );
    }

    final sheet = excel.tables[sheetName]!;
    if (sheet.rows.isEmpty) {
      return ExcelImportPreview(
        fileName: fileName,
        rows: const [
          ExcelVocabRow(
            rowNumber: 1,
            kana: '',
            romaji: '',
            meaning: '',
            error: 'Sheet không có dữ liệu.',
          ),
        ],
      );
    }

    final headers = _readHeaders(sheet.rows.first);
    // last_review được thêm sau định dạng Excel ban đầu. Vẫn hỗ trợ các file
    // backup cũ; file export và template mới luôn có cột này.
    final requiredHeaders = [
      ...excelVocabHeaders.where((header) => header != 'last_review'),
      if (requireFolder) 'folder',
    ];
    final missingHeaders = requiredHeaders
        .where((header) => !headers.containsKey(header))
        .toList();
    if (missingHeaders.isNotEmpty) {
      return ExcelImportPreview(
        fileName: fileName,
        rows: [
          ExcelVocabRow(
            rowNumber: 1,
            kana: '',
            romaji: '',
            meaning: '',
            error: 'Thiếu cột: ${missingHeaders.join(', ')}.',
          ),
        ],
      );
    }

    final rows = <ExcelVocabRow>[];
    for (var i = 1; i < sheet.rows.length; i++) {
      final raw = sheet.rows[i];
      if (raw.every((cell) => _cellText(cell).trim().isEmpty)) {
        continue;
      }

      rows.add(
        _parseRow(
          raw,
          headers,
          i + 1,
          requireFolder: requireFolder,
        ),
      );
    }

    return ExcelImportPreview(fileName: fileName, rows: rows);
  }

  Map<String, int> _readHeaders(List<Data?> row) {
    final headers = <String, int>{};
    for (var i = 0; i < row.length; i++) {
      final text = _cellText(row[i]).trim().toLowerCase();
      if (text.isNotEmpty) {
        headers[text] = i;
      }
    }
    return headers;
  }

  ExcelVocabRow _parseRow(
    List<Data?> row,
    Map<String, int> headers,
    int rowNumber, {
    required bool requireFolder,
  }) {
    final kana = _value(row, headers, 'kana');
    final romaji = _value(row, headers, 'romaji');
    final meaning = _value(row, headers, 'meaning');
    final folderName = _value(row, headers, 'folder');
    final errors = <String>[];

    if (kana.isEmpty) {
      errors.add('kana bắt buộc');
    }
    if (romaji.isEmpty) {
      errors.add('romaji bắt buộc');
    }
    if (meaning.isEmpty) {
      errors.add('meaning bắt buộc');
    }

    if (requireFolder && folderName.isEmpty) {
      errors.add('folder bat buoc');
    }

    final pitchAccentText = _value(row, headers, 'pitch_accent');
    final pitchAccent = pitchAccentText.isEmpty
        ? null
        : normalizePitchPattern(pitchAccentText, kana);
    if (pitchAccentText.isNotEmpty && pitchAccent == null) {
      errors.add('pitch_accent phai la chuoi L/H dung so mora cua kana');
    }

    final levelText = _value(row, headers, 'level');
    final level = levelText.isEmpty ? null : int.tryParse(levelText);
    if (levelText.isNotEmpty && (level == null || level < 0 || level > 6)) {
      errors.add('level phải từ 1 đến 6');
    }

    final nextReviewText = _value(row, headers, 'next_review');
    final nextReview =
        nextReviewText.isEmpty ? null : int.tryParse(nextReviewText);
    if (nextReviewText.isNotEmpty && nextReview == null) {
      errors.add('next_review phải là Unix seconds');
    }

    final lastReviewText = _value(row, headers, 'last_review');
    final lastReview =
        lastReviewText.isEmpty ? null : int.tryParse(lastReviewText);
    if (lastReviewText.isNotEmpty && lastReview == null) {
      errors.add('last_review phải là Unix seconds');
    }

    return ExcelVocabRow(
      rowNumber: rowNumber,
      kanji: _emptyToNull(_value(row, headers, 'kanji')),
      kana: kana,
      romaji: romaji,
      meaning: meaning,
      pitchAccent: pitchAccent,
      example: _emptyToNull(_value(row, headers, 'example')),
      note: _emptyToNull(_value(row, headers, 'note')),
      level: level,
      nextReview: nextReview,
      lastReview: lastReview,
      hasLastReviewColumn: headers.containsKey('last_review'),
      folderName: _emptyToNull(folderName),
      error: errors.isEmpty ? null : errors.join(', '),
    );
  }

  String _value(List<Data?> row, Map<String, int> headers, String header) {
    final index = headers[header];
    if (index == null || index >= row.length) {
      return '';
    }
    return _cellText(row[index]).trim();
  }

  String _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) {
      return '';
    }
    return switch (value) {
      TextCellValue() => value.value.text ?? '',
      IntCellValue() => value.value.toString(),
      DoubleCellValue() => value.value.toString(),
      BoolCellValue() => value.value.toString(),
      DateCellValue() =>
        (value.asDateTimeUtc().millisecondsSinceEpoch ~/ 1000).toString(),
      DateTimeCellValue() =>
        (value.asDateTimeUtc().millisecondsSinceEpoch ~/ 1000).toString(),
      TimeCellValue() => value.toString(),
      FormulaCellValue() => value.formula,
    };
  }

  String? _emptyToNull(String value) {
    return value.trim().isEmpty ? null : value.trim();
  }
}
