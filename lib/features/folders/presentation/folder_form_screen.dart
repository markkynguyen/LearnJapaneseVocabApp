import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/database/app_database.dart';
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
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: controllerState.isLoading ? null : _submit,
                icon: controllerState.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Lưu'),
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

    if (folder == null) {
      await controller.createFolder(
        name: _nameController.text,
        description: _descriptionController.text,
        color: _selectedColor,
      );
    } else {
      await controller.updateFolder(
        id: folder.id,
        name: _nameController.text,
        description: _descriptionController.text,
        color: _selectedColor,
        createdAt: folder.createdAt,
      );
    }

    if (!mounted) {
      return;
    }

    final state = ref.read(folderControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu: ${state.error}')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Đã cập nhật bộ từ' : 'Đã tạo bộ từ'),
      ),
    );
    Navigator.of(context).maybePop();
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
