import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../folders/presentation/providers/folder_provider.dart';
import '../domain/excel_vocab_models.dart';
import 'providers/import_export_provider.dart';

class ExcelImportScreen extends ConsumerStatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  ConsumerState<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends ConsumerState<ExcelImportScreen> {
  String? _folderId;
  ExcelImportPreview? _preview;
  ExcelImportMode _mode = ExcelImportMode.singleFolder;
  DuplicateStrategy _strategy = DuplicateStrategy.skip;

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);
    final controller = ref.watch(importExportControllerProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Import Excel')),
      body: SafeArea(
        child: folders.when(
          data: (folders) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              SegmentedButton<ExcelImportMode>(
                segments: const [
                  ButtonSegment(
                    value: ExcelImportMode.singleFolder,
                    icon: Icon(Icons.folder_rounded),
                    label: Text('Một bộ'),
                  ),
                  ButtonSegment(
                    value: ExcelImportMode.multipleFolders,
                    icon: Icon(Icons.folder_copy_rounded),
                    label: Text('Nhiều bộ'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: controller.isLoading
                    ? null
                    : (value) => setState(() {
                          _mode = value.single;
                          _preview = null;
                        }),
              ),
              if (_mode == ExcelImportMode.singleFolder) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _folderId,
                  decoration: const InputDecoration(
                    labelText: 'Import vào bộ từ',
                    prefixIcon: Icon(Icons.folder_rounded),
                  ),
                  items: [
                    for (final folder in folders)
                      DropdownMenuItem(
                        value: folder.folder.id,
                        child: Text(folder.folder.name),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _folderId = value;
                    _preview = null;
                  }),
                ),
              ] else ...[
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder_copy_rounded),
                    title: const Text('Import theo cột folder'),
                    subtitle: Text(
                      'Mỗi dòng sẽ vào đúng bộ từ theo tên folder; bộ chưa có sẽ được tạo mới.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed:
                    !_canPickFile || controller.isLoading ? null : _pickFile,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('Chọn file .xlsx'),
              ),
              if (_preview != null) ...[
                const SizedBox(height: 18),
                _PreviewSummary(preview: _preview!),
                const SizedBox(height: 14),
                SegmentedButton<DuplicateStrategy>(
                  segments: const [
                    ButtonSegment(
                      value: DuplicateStrategy.skip,
                      icon: Icon(Icons.skip_next_rounded),
                      label: Text('Bỏ qua trùng'),
                    ),
                    ButtonSegment(
                      value: DuplicateStrategy.overwrite,
                      icon: Icon(Icons.sync_rounded),
                      label: Text('Ghi đè'),
                    ),
                  ],
                  selected: {_strategy},
                  onSelectionChanged: (value) {
                    setState(() => _strategy = value.single);
                  },
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: controller.isLoading || _preview!.validCount == 0
                      ? null
                      : _importRows,
                  icon: controller.isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.done_all_rounded),
                  label: const Text('Import dữ liệu'),
                ),
                const SizedBox(height: 14),
                ..._preview!.rows.take(30).map(_PreviewRowTile.new),
                if (_preview!.rows.length > 30)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Chỉ hiển thị 30 dòng đầu để xem nhanh.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Không thể tải folder: $error',
              style: TextStyle(color: context.appDanger),
            ),
          ),
        ),
      ),
    );
  }

  bool get _canPickFile {
    return _mode == ExcelImportMode.multipleFolders || _folderId != null;
  }

  Future<void> _pickFile() async {
    if (_mode == ExcelImportMode.singleFolder && _folderId == null) {
      return;
    }

    final controller = ref.read(importExportControllerProvider.notifier);
    final preview = _mode == ExcelImportMode.singleFolder
        ? await controller.pickPreview(folderId: _folderId!)
        : await controller.pickPreviewMultipleFolders();
    if (!mounted || preview == null) {
      return;
    }
    setState(() => _preview = preview);
  }

  Future<void> _importRows() async {
    final preview = _preview;
    if (preview == null ||
        (_mode == ExcelImportMode.singleFolder && _folderId == null)) {
      return;
    }

    final controller = ref.read(importExportControllerProvider.notifier);
    final result = _mode == ExcelImportMode.singleFolder
        ? await controller.importPreview(
            folderId: _folderId!,
            preview: preview,
            duplicateStrategy: _strategy,
          )
        : await controller.importPreviewMultipleFolders(
            preview: preview,
            duplicateStrategy: _strategy,
          );
    if (!mounted || result == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Import xong: thêm ${result.inserted}, cập nhật ${result.updated}, '
          'bỏ qua ${result.skipped}, lỗi ${result.failed}'
          '${result.createdFolders > 0 ? ', tạo ${result.createdFolders} bộ từ' : ''}.',
        ),
      ),
    );
    Navigator.of(context).maybePop();
  }
}

class _PreviewSummary extends StatelessWidget {
  const _PreviewSummary({required this.preview});

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

class _PreviewRowTile extends StatelessWidget {
  const _PreviewRowTile(this.row);

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
        title: Text(row.kana.isEmpty ? '(thiếu kana)' : row.kana),
        subtitle: Text(
          row.error ?? details,
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
