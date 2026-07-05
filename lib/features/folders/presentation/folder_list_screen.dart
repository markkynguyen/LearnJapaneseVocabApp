import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/app_models.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/folder_provider.dart';
import 'widgets/folder_progress_list.dart';

class FolderListScreen extends ConsumerStatefulWidget {
  const FolderListScreen({super.key});

  @override
  ConsumerState<FolderListScreen> createState() => _FolderListScreenState();
}

class _FolderListScreenState extends ConsumerState<FolderListScreen> {
  List<FolderWithCount>? _draftOrder;
  bool _isSorting = false;
  bool _hasOrderChanges = false;

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);
    final controllerState = ref.watch(folderControllerProvider);
    final isSaving = controllerState.isLoading;
    final canSort = (folders.valueOrNull?.length ?? 0) > 1;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSorting ? 'Sắp xếp bộ từ' : 'Thư viện'),
        actions: [
          if (_isSorting) ...[
            TextButton(
              onPressed: isSaving ? null : _cancelSorting,
              child: const Text('Hủy'),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                onPressed:
                    _hasOrderChanges && !isSaving ? _saveFolderOrder : null,
                icon: isSaving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text('Lưu'),
              ),
            ),
          ] else if (canSort)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _startSorting,
                icon: const Icon(Icons.swap_vert_rounded),
                label: const Text('Sắp xếp'),
              ),
            ),
        ],
      ),
      floatingActionButton: _isSorting
          ? null
          : FloatingActionButton(
              onPressed: () => context.push(AppRoutes.newFolder),
              child: const Icon(Icons.add_rounded),
            ),
      body: SafeArea(
        child: folders.when(
          data: (items) {
            final visibleItems = _isSorting
                ? (_draftOrder ??= List<FolderWithCount>.of(items))
                : items;
            return AbsorbPointer(
              absorbing: isSaving,
              child: Column(
                children: [
                  if (isSaving) const LinearProgressIndicator(),
                  if (_isSorting)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.drag_indicator_rounded,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Giữ biểu tượng kéo và di chuyển bộ từ đến vị trí mong muốn.',
                              style: TextStyle(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: FolderProgressList(
                      folders: visibleItems,
                      reorderEnabled: _isSorting,
                      onReorder: _reorderFolder,
                      onOpenFolder: (id) =>
                          context.push(AppRoutes.folderVocab(id)),
                      onEditFolder: (item) => context.push(
                        AppRoutes.editFolder(item.folder.id),
                        extra: item.folder,
                      ),
                      onDeleteFolder: (item) =>
                          _confirmDelete(context, ref, item),
                    ),
                  ),
                ],
              ),
            );
          },
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

  void _startSorting() {
    final items = ref.read(foldersProvider).valueOrNull;
    if (items == null || items.length < 2) return;
    setState(() {
      _draftOrder = List<FolderWithCount>.of(items);
      _isSorting = true;
      _hasOrderChanges = false;
    });
  }

  void _cancelSorting() {
    setState(() {
      _draftOrder = null;
      _isSorting = false;
      _hasOrderChanges = false;
    });
  }

  void _reorderFolder(int oldIndex, int newIndex) {
    final items = _draftOrder;
    if (items == null) return;
    setState(() {
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      _hasOrderChanges = true;
    });
  }

  Future<void> _saveFolderOrder() async {
    final items = _draftOrder;
    if (items == null || !_hasOrderChanges) return;

    await ref.read(folderControllerProvider.notifier).reorderFolders(
          items.map((item) => item.folder.id).toList(growable: false),
        );
    if (!mounted) return;

    final state = ref.read(folderControllerProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu thứ tự: ${state.error}')),
      );
      return;
    }

    setState(() {
      _draftOrder = null;
      _isSorting = false;
      _hasOrderChanges = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã lưu thứ tự bộ từ.')),
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

    if (confirmed != true || !context.mounted) return;

    await ref.read(folderControllerProvider.notifier).deleteFolder(
          item.folder.id,
        );
    if (!context.mounted) return;

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
