import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/excel_vocab_models.dart';

class ExcelImportPreviewSummary extends StatelessWidget {
  const ExcelImportPreviewSummary({required this.preview, super.key});

  final ExcelImportPreview preview;

  @override
  Widget build(BuildContext context) {
    final folderCount = preview.rows
        .map((row) => row.folderName?.trim())
        .where((name) => name != null && name.isNotEmpty)
        .toSet()
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              preview.fileName,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Hợp lệ ${preview.validCount} • Trùng ${preview.duplicateCount} • '
              'Lỗi ${preview.errorCount}'
              '${folderCount > 0 ? ' • $folderCount bộ từ' : ''}',
            ),
          ],
        ),
      ),
    );
  }
}

class ExcelImportPreviewRowTile extends StatelessWidget {
  const ExcelImportPreviewRowTile(this.row, {super.key});

  final ExcelVocabRow row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final statusColor = !row.isValid
        ? context.appDanger
        : row.isDuplicate
            ? context.appWarning
            : context.appSuccess;
    final folderName = row.folderName;
    final details = [
      if (folderName != null && folderName.trim().isNotEmpty) folderName.trim(),
      row.romaji,
      row.meaning,
      if (row.isDuplicate) 'trùng kana',
    ].where((item) => item.trim().isNotEmpty).join(' • ');

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.14),
          child: Text(
            '${row.rowNumber}',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(
          row.kana.isEmpty ? '(thiếu kana)' : row.kana,
          locale: AppTypography.japaneseLocale,
          style: AppTypography.japanese(
            context,
            Theme.of(context).textTheme.titleMedium,
          ),
        ),
        subtitle: Text(
          row.error ?? details,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
