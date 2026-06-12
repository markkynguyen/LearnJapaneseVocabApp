import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/folder_provider.dart';

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
          data: (items) => items.isEmpty
              ? const _EmptyFolders()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _FolderTile(
                      item: item,
                      onOpen: () =>
                          context.push(AppRoutes.folderVocab(item.folder.id)),
                      onEdit: () => context.push(
                        AppRoutes.editFolder(item.folder.id),
                        extra: item.folder,
                      ),
                      onDelete: () => _confirmDelete(context, ref, item),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemCount: items.length,
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Khong the tai bo tu: $error',
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
        title: const Text('Xoa bo tu?'),
        content: Text(
          'Xoa bo tu nay se xoa toan bo ${item.totalWords} tu vung. '
          'Khong the hoan tac.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoa'),
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
          state.hasError ? 'Khong the xoa: ${state.error}' : 'Da xoa bo tu',
        ),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({
    required this.item,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final FolderWithCount item;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final folder = item.folder;
    final colors = Theme.of(context).colorScheme;
    final color = Color(
      0xFF000000 |
          (int.tryParse(folder.color.replaceFirst('#', ''), radix: 16) ?? 0),
    );

    return Card(
      child: ListTile(
        onTap: onOpen,
        leading: Icon(Icons.folder_rounded, color: color),
        title: Text(
          folder.name,
          style: TextStyle(color: colors.onSurface),
        ),
        subtitle: Text('${item.totalWords} từ - ${item.dueCount} cần ôn'),
        trailing: PopupMenuButton<_FolderAction>(
          onSelected: (action) {
            switch (action) {
              case _FolderAction.edit:
                onEdit();
              case _FolderAction.delete:
                onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _FolderAction.edit,
              child: Text('Sửa bộ từ'),
            ),
            PopupMenuItem(
              value: _FolderAction.delete,
              child: Text('Xóa bộ từ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFolders extends StatelessWidget {
  const _EmptyFolders();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Text(
        'Chưa có bộ từ nào.',
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
    );
  }
}

enum _FolderAction { edit, delete }
