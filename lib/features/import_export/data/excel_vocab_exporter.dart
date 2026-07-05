import 'package:excel/excel.dart';

import '../../../core/pitch_accent/pitch_accent_utils.dart';
import '../domain/excel_vocab_models.dart';

class ExcelVocabExporter {
  const ExcelVocabExporter();

  List<int> exportBundles(List<ExportFolderBundle> bundles) {
    final excel = Excel.createExcel();
    const sheetName = 'jvocab';
    final sheet = excel[sheetName];
    if (excel.getDefaultSheet() != sheetName) {
      excel.delete('Sheet1');
    }

    sheet.appendRow([
      ...excelVocabHeaders.map(TextCellValue.new),
      TextCellValue('folder'),
    ]);

    for (final bundle in bundles) {
      for (final item in bundle.items) {
        final vocab = item.vocab;
        final progress = item.progress;
        sheet.appendRow([
          _text(vocab.kanji),
          TextCellValue(vocab.kana),
          TextCellValue(vocab.romaji),
          TextCellValue(vocab.meaning),
          _pitch(vocab.pitchAccent, vocab.kana),
          _text(vocab.example),
          _text(vocab.note),
          IntCellValue(progress.level),
          IntCellValue(progress.nextReviewAt),
          progress.lastReviewedAt == null
              ? null
              : IntCellValue(progress.lastReviewedAt!),
          TextCellValue(bundle.folder.name),
        ]);
      }
    }

    return excel.encode() ?? <int>[];
  }

  List<int> exportTemplate() {
    final excel = Excel.createExcel();
    const sheetName = 'jvocab';
    final sheet = excel[sheetName];
    if (excel.getDefaultSheet() != sheetName) {
      excel.delete('Sheet1');
    }

    sheet.appendRow(excelVocabHeaders.map(TextCellValue.new).toList());
    sheet.appendRow([
      TextCellValue('食べる'),
      TextCellValue('たべる'),
      TextCellValue('taberu'),
      TextCellValue('an'),
      TextCellValue('LHL'),
      TextCellValue('朝ご飯を食べます。'),
      TextCellValue('Dong nghia: 食う; luu y lich su dung.'),
      const IntCellValue(1),
      null,
      null,
    ]);

    return excel.encode() ?? <int>[];
  }

  TextCellValue? _text(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return TextCellValue(trimmed);
  }

  TextCellValue? _pitch(String? value, String kana) {
    final normalized = normalizePitchPattern(value, kana);
    return normalized == null ? null : TextCellValue(normalized);
  }
}
