import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_theme.dart';

class FolderProgressList extends StatelessWidget {
  const FolderProgressList({
    required this.folders,
    required this.onOpenFolder,
    required this.onEditFolder,
    required this.onDeleteFolder,
    this.reorderEnabled = false,
    this.onReorder,
    super.key,
  });

  final List<FolderWithCount> folders;
  final ValueChanged<String> onOpenFolder;
  final ValueChanged<FolderWithCount> onEditFolder;
  final ValueChanged<FolderWithCount> onDeleteFolder;
  final bool reorderEnabled;
  final ReorderCallback? onReorder;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const _EmptyFolderState();
    }

    if (reorderEnabled) {
      assert(onReorder != null);
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
        buildDefaultDragHandles: false,
        itemCount: folders.length,
        onReorderItem: onReorder!,
        itemBuilder: (context, index) {
          final item = folders[index];
          return Padding(
            key: ValueKey(item.folder.id),
            padding: const EdgeInsets.only(bottom: 10),
            child: _FolderProgressCard(
              item: item,
              dragHandle: ReorderableDelayedDragStartListener(
                index: index,
                child: const Tooltip(
                  message: 'Kéo để sắp xếp',
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle_rounded),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
      itemCount: folders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = folders[index];
        return _FolderProgressCard(
          key: ValueKey(item.folder.id),
          item: item,
          onTap: () => onOpenFolder(item.folder.id),
          onEdit: () => onEditFolder(item),
          onDelete: () => onDeleteFolder(item),
        );
      },
    );
  }
}

double folderCompletionRate(FolderWithCount item) {
  if (item.totalWords == 0) {
    return 0;
  }
  return (item.totalWords - item.unlearnedCount) / item.totalWords;
}

class _FolderProgressCard extends StatelessWidget {
  const _FolderProgressCard({
    required this.item,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.dragHandle,
    super.key,
  });

  final FolderWithCount item;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final folderColor = _parseColor(item.folder.color);
    final completionRate = folderCompletionRate(item);
    final percent = (completionRate * 100).round();
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_rounded, color: folderColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (item.dueCount > 0) _DueBadge(count: item.dueCount),
                  if (dragHandle != null)
                    dragHandle!
                  else
                    PopupMenuButton<_FolderAction>(
                      tooltip: 'Tùy chọn bộ từ',
                      onSelected: (action) {
                        switch (action) {
                          case _FolderAction.edit:
                            onEdit?.call();
                          case _FolderAction.delete:
                            onDelete?.call();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: _FolderAction.edit,
                          child: Row(
                            children: [
                              Icon(Icons.edit_rounded),
                              SizedBox(width: 10),
                              Text('Sửa bộ từ'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: _FolderAction.delete,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded),
                              SizedBox(width: 10),
                              Text('Xóa bộ từ'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${item.totalWords} từ • ${item.unlearnedCount} từ chưa học',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: completionRate,
                        backgroundColor: colors.outline.withValues(alpha: 0.4),
                        color: folderColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$percent% đã học',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String value) {
    final hex = value.replaceFirst('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? AppColors.primary : Color(0xFF000000 | parsed);
  }
}

class _DueBadge extends StatelessWidget {
  const _DueBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.appDanger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count cần ôn',
        style: TextStyle(
          color: context.appDanger,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyFolderState extends StatelessWidget {
  const _EmptyFolderState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_off_outlined,
              size: 44,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có bộ từ nào.',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

enum _FolderAction { edit, delete }
