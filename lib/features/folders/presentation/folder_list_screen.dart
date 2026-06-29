import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/folder_provider.dart';
import 'widgets/folder_progress_list.dart';

class FolderListScreen extends ConsumerWidget {
  const FolderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(foldersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thư viện')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newFolder),
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: folders.when(
          data: (items) => FolderProgressList(
            folders: items,
            onOpenFolder: (id) => context.push(AppRoutes.folderVocab(id)),
            onEditFolder: (item) => context.push(
              AppRoutes.editFolder(item.folder.id),
              extra: item.folder,
            ),
            onDeleteFolder: (item) => _confirmDelete(context, ref, item),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Không thể tải bộ từ: $error',
              style: TextStyle(color: context.appDanger),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    FolderWithCount item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bộ từ?'),
        content: Text(
          'Xóa bộ từ này sẽ xóa toàn bộ ${item.totalWords} từ vựng. '
          'Không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await ref.read(folderControllerProvider.notifier).deleteFolder(
          item.folder.id,
        );

    if (!context.mounted) {
      return;
    }

    final state = ref.read(folderControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state.hasError ? 'Không thể xóa: ${state.error}' : 'Đã xóa bộ từ',
        ),
      ),
    );
  }
}
