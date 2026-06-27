import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/home_provider.dart';

class FolderProgressList extends StatelessWidget {
  const FolderProgressList({
    required this.folders,
    required this.onOpenFolder,
    super.key,
  });

  final List<FolderSummary> folders;
  final ValueChanged<int> onOpenFolder;

  @override
  Widget build(BuildContext context) {
    if (folders.isEmpty) {
      return const _EmptyFolderState();
    }

    return Column(
      children: folders
          .map(
            (folder) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FolderProgressCard(
                summary: folder,
                onTap: () => onOpenFolder(folder.folder.id),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FolderProgressCard extends StatelessWidget {
  const _FolderProgressCard({
    required this.summary,
    required this.onTap,
  });

  final FolderSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final folderColor = _parseColor(summary.folder.color);
    final percent = (summary.completionRate * 100).round();
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_rounded, color: folderColor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      summary.folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  if (summary.dueCount > 0) _DueBadge(count: summary.dueCount),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${summary.totalWords} từ • ${summary.unlearnedCount} từ chưa học',
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
                        value: summary.completionRate,
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
    if (parsed == null) {
      return AppColors.primary;
    }

    return Color(0xFF000000 | parsed);
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Chưa có bộ từ nào.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}
