import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/features/import_export/data/excel_vocab_parser.dart';
import 'package:jvocab/features/import_export/domain/excel_vocab_models.dart';

void main() {
  test('parses vocabulary rows including note', () {
    final excel = Excel.createExcel();
    final sheet = excel['jvocab'];
    excel.delete('Sheet1');
    sheet.appendRow(excelVocabHeaders.map(TextCellValue.new).toList());
    sheet.appendRow([
      TextCellValue('食べる'),
      TextCellValue('たべる'),
      TextCellValue('taberu'),
      TextCellValue('ăn'),
      null,
      TextCellValue('朝ご飯を食べます。'),
      TextCellValue('Đồng nghĩa: 食う'),
      const IntCellValue(3),
      const IntCellValue(1780000000),
      const IntCellValue(1770000000),
    ]);

    final preview = const ExcelVocabParser().parse(
      bytes: excel.encode()!,
      fileName: 'sample.xlsx',
    );

    expect(preview.validCount, 1);
    expect(preview.rows.single.note, 'Đồng nghĩa: 食う');
    expect(preview.rows.single.level, 3);
    expect(preview.rows.single.nextReview, 1780000000);
    expect(preview.rows.single.lastReview, 1770000000);
    expect(preview.rows.single.hasLastReviewColumn, isTrue);
  });

  test('accepts level 0 for unlearned vocabulary', () {
    final excel = Excel.createExcel();
    final sheet = excel['jvocab'];
    excel.delete('Sheet1');
    sheet.appendRow(excelVocabHeaders.map(TextCellValue.new).toList());
    sheet.appendRow([
      null,
      TextCellValue('あたらしい'),
      TextCellValue('atarashii'),
      TextCellValue('new'),
      null,
      null,
      null,
      const IntCellValue(0),
      null,
    ]);

    final preview = const ExcelVocabParser().parse(
      bytes: excel.encode()!,
      fileName: 'level0.xlsx',
    );

    expect(preview.validCount, 1);
    expect(preview.rows.single.level, 0);
  });

  test('parses pitch accent as L/H pattern', () {
    final excel = Excel.createExcel();
    final sheet = excel['jvocab'];
    excel.delete('Sheet1');
    sheet.appendRow(excelVocabHeaders.map(TextCellValue.new).toList());
    sheet.appendRow([
      null,
      TextCellValue('たまご'),
      TextCellValue('tamago'),
      TextCellValue('egg'),
      TextCellValue('LHL'),
      null,
      null,
      const IntCellValue(0),
      null,
    ]);

    final preview = const ExcelVocabParser().parse(
      bytes: excel.encode()!,
      fileName: 'pitch.xlsx',
    );

    expect(preview.validCount, 1);
    expect(preview.rows.single.pitchAccent, 'LHL');
  });

  test('rejects pitch accent with invalid L/H pattern', () {
    final excel = Excel.createExcel();
    final sheet = excel['jvocab'];
    excel.delete('Sheet1');
    sheet.appendRow(excelVocabHeaders.map(TextCellValue.new).toList());
    sheet.appendRow([
      null,
      TextCellValue('たまご'),
      TextCellValue('tamago'),
      TextCellValue('egg'),
      TextCellValue('LH'),
      null,
      null,
      const IntCellValue(0),
      null,
    ]);

    final preview = const ExcelVocabParser().parse(
      bytes: excel.encode()!,
      fileName: 'pitch-invalid.xlsx',
    );

    expect(preview.validCount, 0);
    expect(preview.rows.single.error, contains('pitch_accent'));
  });

  test('parses folder column for multi-folder backup imports', () {
    final excel = Excel.createExcel();
    final sheet = excel['jvocab'];
    excel.delete('Sheet1');
    sheet.appendRow([
      ...excelVocabHeaders.map(TextCellValue.new),
      TextCellValue('folder'),
    ]);
    sheet.appendRow([
      null,
      TextCellValue('ã­ã“'),
      TextCellValue('neko'),
      TextCellValue('cat'),
      null,
      null,
      null,
      const IntCellValue(1),
      null,
      null,
      TextCellValue('N5 nouns'),
    ]);

    final preview = const ExcelVocabParser().parse(
      bytes: excel.encode()!,
      fileName: 'backup.xlsx',
      requireFolder: true,
    );

    expect(preview.validCount, 1);
    expect(preview.rows.single.folderName, 'N5 nouns');
  });

  test('requires folder column for multi-folder imports', () {
    final excel = Excel.createExcel();
    final sheet = excel['jvocab'];
    excel.delete('Sheet1');
    sheet.appendRow(excelVocabHeaders.map(TextCellValue.new).toList());
    sheet.appendRow([
      null,
      TextCellValue('ã„ã¬'),
      TextCellValue('inu'),
      TextCellValue('dog'),
      null,
      null,
      null,
      const IntCellValue(1),
      null,
    ]);

    final preview = const ExcelVocabParser().parse(
      bytes: excel.encode()!,
      fileName: 'missing-folder.xlsx',
      requireFolder: true,
    );

    expect(preview.validCount, 0);
    expect(preview.rows.single.error, contains('folder'));
  });

  test('accepts legacy files without last_review column', () {
    final excel = Excel.createExcel();
    final sheet = excel['jvocab'];
    excel.delete('Sheet1');
    final legacyHeaders =
        excelVocabHeaders.where((header) => header != 'last_review');
    sheet.appendRow(legacyHeaders.map(TextCellValue.new).toList());
    sheet.appendRow([
      null,
      TextCellValue('いぬ'),
      TextCellValue('inu'),
      TextCellValue('dog'),
      null,
      null,
      null,
      const IntCellValue(2),
      const IntCellValue(1780000000),
    ]);

    final preview = const ExcelVocabParser().parse(
      bytes: excel.encode()!,
      fileName: 'legacy.xlsx',
    );

    expect(preview.validCount, 1);
    expect(preview.rows.single.lastReview, isNull);
    expect(preview.rows.single.hasLastReviewColumn, isFalse);
  });
}
