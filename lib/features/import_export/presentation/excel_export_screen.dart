import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../folders/presentation/providers/folder_provider.dart';
import 'providers/import_export_provider.dart';

class ExcelExportScreen extends ConsumerStatefulWidget {
  const ExcelExportScreen({super.key});

  @override
  ConsumerState<ExcelExportScreen> createState() => _ExcelExportScreenState();
}

class _ExcelExportScreenState extends ConsumerState<ExcelExportScreen> {
  int? _folderId;

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);
    final controller = ref.watch(importExportControllerProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Export Excel')),
      body: SafeArea(
        child: folders.when(
          data: (folders) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Export dùng các cột: kanji, kana, romaji, meaning, '
                    'pitch_accent, example, note, level, next_review.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: _folderId,
                decoration: const InputDecoration(
                  labelText: 'Chọn bộ từ',
                  prefixIcon: Icon(Icons.folder_rounded),
                ),
                items: [
                  for (final folder in folders)
                    DropdownMenuItem(
                      value: folder.folder.id,
                      child: Text(folder.folder.name),
                    ),
                ],
                onChanged: controller.isLoading
                    ? null
                    : (value) => setState(() => _folderId = value),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _folderId == null || controller.isLoading
                    ? null
                    : () => _exportFolder(_folderId!),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('Export bộ từ đã chọn'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: controller.isLoading ? null : _exportAll,
                icon: controller.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.backup_rounded),
                label: const Text('Export tất cả bộ từ'),
              ),
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

  Future<void> _exportFolder(int folderId) async {
    final path = await ref
        .read(importExportControllerProvider.notifier)
        .exportFolder(folderId);
    _showResult(path);
  }

  Future<void> _exportAll() async {
    final path =
        await ref.read(importExportControllerProvider.notifier).exportAll();
    _showResult(path);
  }

  void _showResult(String? path) {
    if (!mounted || path == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã tạo file: $path')),
    );
  }
}
