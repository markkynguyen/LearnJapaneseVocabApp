import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/app_models.dart';
import '../../import_export/domain/excel_vocab_models.dart';
import '../../import_export/presentation/providers/import_export_provider.dart';
import '../../import_export/presentation/widgets/excel_import_preview_widgets.dart';
import 'providers/folder_provider.dart';
import 'widgets/folder_color_picker.dart';

class FolderFormScreen extends ConsumerStatefulWidget {
  const FolderFormScreen({
    this.folder,
    super.key,
  });

  final Folder? folder;

  @override
  ConsumerState<FolderFormScreen> createState() => _FolderFormScreenState();
}

class _FolderFormScreenState extends ConsumerState<FolderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _selectedColor;
  ExcelImportPreview? _excelPreview;

  bool get _isEditing => widget.folder != null;

  @override
  void initState() {
    super.initState();
    final folder = widget.folder;
    _nameController = TextEditingController(text: folder?.name);
    _descriptionController = TextEditingController(
      text: folder?.description ?? '',
    );
    _selectedColor =
        folder?.color ?? FolderColorPicker.colorToHex(AppColors.primary);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(folderControllerProvider);
    final importState = ref.watch(importExportControllerProvider);
    final isLoading = controllerState.isLoading || importState.isLoading;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Sửa bộ từ' : 'Tạo bộ từ mới'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 50,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Tên bộ từ',
                  hintText: 'VD: N5 Động từ',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Vui lòng nhập tên bộ từ';
                  }
                  if (trimmed.length > 50) {
                    return 'Tên bộ từ tối đa 50 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  hintText: 'Ghi chú ngắn về bộ từ này',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.length > 200) {
                    return 'Mô tả tối đa 200 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              Text(
                'Màu bộ từ',
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              FolderColorPicker(
                selectedColor: _selectedColor,
                onChanged: (color) => setState(() => _selectedColor = color),
              ),
              const SizedBox(height: 22),
              _FolderPreviewCard(
                name: _nameController.text.trim().isEmpty
                    ? 'Tên bộ từ'
                    : _nameController.text.trim(),
                description: _descriptionController.text.trim(),
                color: _selectedColor,
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 18),
                _ExcelImportSection(
                  preview: _excelPreview,
                  isLoading: importState.isLoading,
                  onPickFile: _pickExcelFile,
                  onClearFile: _clearExcelFile,
                ),
              ],
              const SizedBox(height: 28),
              KeyedSubtree(
                key: const ValueKey('folder-form-save-button'),
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final folder = widget.folder;
    final controller = ref.read(folderControllerProvider.notifier);
    final importController = ref.read(importExportControllerProvider.notifier);

    if (folder == null) {
      final preview = _excelPreview;
      if (preview != null && preview.validCount == 0) {
        _showSnackBar('File Excel chưa có dòng hợp lệ để import.');
        return;
      }

      final folderId = await controller.createFolder(
        name: _nameController.text,
        description: _descriptionController.text,
        color: _selectedColor,
      );
      if (!mounted) {
        return;
      }
      final folderState = ref.read(folderControllerProvider);
      if (folderState.hasError || folderId == null) {
        _showSnackBar('Không thể lưu: ${folderState.error}');
        return;
      }

      if (preview != null) {
        final result = await importController.importPreview(
          folderId: folderId,
          preview: preview,
          duplicateStrategy: DuplicateStrategy.skip,
        );
        if (!mounted) {
          return;
        }
        ref.invalidate(foldersProvider);
        if (result == null) {
          final importState = ref.read(importExportControllerProvider);
          _showSnackBar(
            'Đã tạo bộ từ nhưng chưa import được dữ liệu: ${importState.error}',
          );
          Navigator.of(context).maybePop();
          return;
        }
        _showSnackBar(
          'Đã tạo bộ từ và import: thêm ${result.inserted}, '
          'bỏ qua ${result.skipped}, lỗi ${result.failed}.',
        );
        Navigator.of(context).maybePop();
        return;
      }
    } else {
      await controller.updateFolder(
        id: folder.id,
        name: _nameController.text,
        description: _descriptionController.text,
        color: _selectedColor,
      );
    }

    if (!mounted) {
      return;
    }

    final state = ref.read(folderControllerProvider);
    if (state.hasError) {
      _showSnackBar('Không thể lưu: ${state.error}');
      return;
    }

    _showSnackBar(_isEditing ? 'Đã cập nhật bộ từ' : 'Đã tạo bộ từ');
    Navigator.of(context).maybePop();
  }

  Future<void> _pickExcelFile() async {
    final preview = await ref
        .read(importExportControllerProvider.notifier)
        .pickPreviewForNewFolder();
    if (!mounted) {
      return;
    }
    if (preview == null) {
      final state = ref.read(importExportControllerProvider);
      if (state.hasError) {
        _showSnackBar('Không thể đọc file Excel: ${state.error}');
      }
      return;
    }
    setState(() => _excelPreview = preview);
    if (preview.ignoredBlankRowCount > 0) {
      _showSnackBar(
        'Đã bỏ qua ${preview.ignoredBlankRowCount} hàng trống trong file.',
      );
    }
  }

  void _clearExcelFile() {
    setState(() => _excelPreview = null);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ExcelImportSection extends StatelessWidget {
  const _ExcelImportSection({
    required this.preview,
    required this.isLoading,
    required this.onPickFile,
    required this.onClearFile,
  });

  final ExcelImportPreview? preview;
  final bool isLoading;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final preview = this.preview;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nạp từ vựng bằng Excel',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isLoading ? null : onPickFile,
                icon: isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file_rounded),
                label: Text(preview == null ? 'Chọn file .xlsx' : 'Đổi file'),
              ),
            ),
            if (preview != null) ...[
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Bỏ file Excel',
                onPressed: isLoading ? null : onClearFile,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ],
        ),
        if (preview != null) ...[
          const SizedBox(height: 12),
          ExcelImportPreviewSummary(preview: preview),
          const SizedBox(height: 8),
          ...preview.rows.take(30).map(ExcelImportPreviewRowTile.new),
          if (preview.rows.length > 30)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Chỉ hiển thị 30 dòng đầu để xem nhanh.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ),
        ],
      ],
    );
  }
}

class _FolderPreviewCard extends StatelessWidget {
  const _FolderPreviewCard({
    required this.name,
    required this.description,
    required this.color,
  });

  final String name;
  final String description;
  final String color;

  @override
  Widget build(BuildContext context) {
    final previewColor = Color(
      0xFF000000 | (int.tryParse(color.replaceFirst('#', ''), radix: 16) ?? 0),
    );
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.folder_rounded, color: previewColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
