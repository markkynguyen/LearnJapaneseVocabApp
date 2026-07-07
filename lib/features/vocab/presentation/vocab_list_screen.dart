import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/app_models.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import 'providers/vocab_list_provider.dart';
import 'widgets/vocab_card.dart';

class VocabListScreen extends ConsumerStatefulWidget {
  const VocabListScreen({
    required this.folderId,
    this.folderName,
    super.key,
  });

  final String folderId;
  final String? folderName;

  @override
  ConsumerState<VocabListScreen> createState() => _VocabListScreenState();
}

class _VocabListScreenState extends ConsumerState<VocabListScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFavorites = ref.watch(hasFavoriteVocabProvider(widget.folderId));
    final list = ref.watch(vocabListProvider(widget.folderId));
    final favorites = ref.watch(favoriteVocabListProvider(widget.folderId));
    final sortMode = ref.watch(vocabSortProvider(widget.folderId));
    final dueCount = ref.watch(folderDueCountProvider(widget.folderId));
    final unlearnedCount =
        ref.watch(folderUnlearnedCountProvider(widget.folderId));
    final canLearnNewWords = (unlearnedCount.valueOrNull ?? 0) > 0;

    return DefaultTabController(
      length: hasFavorites.valueOrNull == true ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.folderName ?? 'Từ vựng'),
          actions: [
            IconButton(
              tooltip: 'Flashcards',
              onPressed: _openFlashcards,
              icon: const Icon(Icons.style_rounded),
            ),
            IconButton(
              tooltip: 'Thêm từ',
              onPressed: _openCreateForm,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
          bottom: hasFavorites.valueOrNull == true
              ? const TabBar(
                  tabs: [
                    Tab(text: 'Tất cả'),
                    Tab(text: 'Yêu thích'),
                  ],
                )
              : null,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                children: [
                  SegmentedButton<VocabSortMode>(
                    segments: const [
                      ButtonSegment(
                        value: VocabSortMode.newest,
                        icon: Icon(Icons.schedule_rounded),
                        label: Text('Mới nhất'),
                      ),
                      ButtonSegment(
                        value: VocabSortMode.oldest,
                        icon: Icon(Icons.history_rounded),
                        label: Text('Cũ nhất'),
                      ),
                      ButtonSegment(
                        value: VocabSortMode.dueTime,
                        icon: Icon(Icons.event_rounded),
                        label: Text('Ôn lại'),
                      ),
                    ],
                    selected: {sortMode},
                    onSelectionChanged: (value) {
                      ref
                          .read(vocabSortProvider(widget.folderId).notifier)
                          .update(value.single);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText:
                          'Tìm kanji, kana, romaji, nghĩa hoặc ghi chú...',
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ],
              ),
            ),
            Expanded(
              child: hasFavorites.valueOrNull == true
                  ? TabBarView(
                      children: [
                        _VocabListBody(
                          items: list,
                          onAction: _handleAction,
                          summaryCard: _FolderDueSummaryCard(
                            dueCount: dueCount,
                            unlearnedCount: unlearnedCount,
                          ),
                          learningAction: canLearnNewWords
                              ? _ReviewListAction(
                                  icon: Icons.auto_stories_rounded,
                                  label: 'Học từ mới',
                                  onPressed: () => context.push(
                                    AppRoutes.learningPreview(widget.folderId),
                                  ),
                                )
                              : null,
                          reviewAction: _ReviewListAction(
                            icon: Icons.school_rounded,
                            label: 'Ôn bộ từ',
                            onPressed: () => context.push(
                              AppRoutes.reviewFolder(widget.folderId),
                            ),
                          ),
                        ),
                        _VocabListBody(
                          items: favorites,
                          onAction: _handleAction,
                          reviewAction: _ReviewListAction(
                            icon: Icons.favorite_rounded,
                            label: 'Ôn yêu thích',
                            onPressed: () => context.push(
                              AppRoutes.reviewFolder(
                                widget.folderId,
                                favoritesOnly: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : _VocabListBody(
                      items: list,
                      onAction: _handleAction,
                      summaryCard: _FolderDueSummaryCard(
                        dueCount: dueCount,
                        unlearnedCount: unlearnedCount,
                      ),
                      learningAction: canLearnNewWords
                          ? _ReviewListAction(
                              icon: Icons.auto_stories_rounded,
                              label: 'Học từ mới',
                              onPressed: () => context.push(
                                AppRoutes.learningPreview(widget.folderId),
                              ),
                            )
                          : null,
                      reviewAction: _ReviewListAction(
                        icon: Icons.school_rounded,
                        label: 'Ôn bộ từ',
                        onPressed: () => context.push(
                          AppRoutes.reviewFolder(widget.folderId),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(vocabSearchQueryProvider(widget.folderId).notifier)
          .update(value);
    });
  }

  Future<void> _handleAction(
    BuildContext context,
    VocabWithProgress item,
    VocabCardAction action,
  ) async {
    final controller = ref.read(vocabListControllerProvider.notifier);

    switch (action) {
      case VocabCardAction.edit:
        _openEditForm(item.vocab.id);
      case VocabCardAction.minusOne:
        await controller.manualMinus1(item);
        if (context.mounted) {
          _showSnackBar(context, 'Đã giảm 1 level');
        }
      case VocabCardAction.reset:
        await controller.manualReset(item);
        if (context.mounted) {
          _showSnackBar(context, 'Đã reset về Lv 1');
        }
      case VocabCardAction.delete:
        await _confirmDelete(context, controller, item);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    VocabListController controller,
    VocabWithProgress item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa từ này?'),
        content: Text(
          'Từ "${item.vocab.kana}" sẽ bị xóa khỏi bộ từ. Không thể hoàn tác.',
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

    if (confirmed != true) {
      return;
    }

    await controller.deleteVocab(item.vocab);
    if (context.mounted) {
      _showSnackBar(context, 'Đã xóa từ');
    }
  }

  void _openCreateForm() {
    context.push(AppRoutes.newVocab(widget.folderId));
  }

  void _openFlashcards() {
    context.push(AppRoutes.folderFlashcards(widget.folderId));
  }

  void _openEditForm(String vocabId) {
    context.push(AppRoutes.editVocab(vocabId, folderId: widget.folderId));
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _FolderDueSummaryCard extends StatelessWidget {
  const _FolderDueSummaryCard({
    required this.dueCount,
    required this.unlearnedCount,
  });

  final AsyncValue<int> dueCount;
  final AsyncValue<int> unlearnedCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kế hoạch học tập',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StudyCountTile(
                    count: unlearnedCount,
                    icon: Icons.auto_stories_rounded,
                    label: 'Từ cần học',
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StudyCountTile(
                    count: dueCount,
                    icon: Icons.school_rounded,
                    label: 'Từ cần ôn',
                    color: context.appWarning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StudyCountTile extends StatelessWidget {
  const _StudyCountTile({
    required this.count,
    required this.icon,
    required this.label,
    required this.color,
  });

  final AsyncValue<int> count;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          count.when(
            data: (value) => Text(
              '$value',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            loading: () => SizedBox.square(
              dimension: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
              ),
            ),
            error: (_, __) => Icon(
              Icons.error_outline_rounded,
              color: colors.error,
              size: 26,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _VocabListBody extends ConsumerWidget {
  const _VocabListBody({
    required this.items,
    required this.onAction,
    this.summaryCard,
    this.learningAction,
    this.reviewAction,
  });

  final AsyncValue<List<VocabWithProgress>> items;
  final Future<void> Function(
    BuildContext context,
    VocabWithProgress item,
    VocabCardAction action,
  ) onAction;
  final Widget? summaryCard;
  final _ReviewListAction? learningAction;
  final _ReviewListAction? reviewAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return items.when(
      data: (items) {
        final leading = <Widget>[
          if (summaryCard != null) summaryCard!,
          if (learningAction != null)
            FilledButton.icon(
              onPressed: learningAction!.onPressed,
              icon: Icon(learningAction!.icon),
              label: Text(learningAction!.label),
            ),
          if (reviewAction != null)
            OutlinedButton.icon(
              onPressed: reviewAction!.onPressed,
              icon: Icon(reviewAction!.icon),
              label: Text(reviewAction!.label),
            ),
        ];

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
          itemBuilder: (context, index) {
            if (index < leading.length) {
              return leading[index];
            }
            if (items.isEmpty) {
              return const _EmptyVocabState();
            }
            final itemIndex = index - leading.length;
            final item = items[itemIndex];
            final favoriteOverride =
                ref.watch(favoriteOverrideProvider(item.vocab.id));
            return VocabCard(
              item: item,
              isFavoriteOverride: favoriteOverride,
              onToggleFavorite: () => ref
                  .read(vocabListControllerProvider.notifier)
                  .toggleFavorite(item),
              onAction: (action) => onAction(context, item, action),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: leading.length + (items.isEmpty ? 1 : items.length),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Không thể tải từ vựng: $error',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appDanger),
          ),
        ),
      ),
    );
  }
}

class _ReviewListAction {
  const _ReviewListAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
}

class _EmptyVocabState extends StatelessWidget {
  const _EmptyVocabState();

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
              Icons.menu_book_rounded,
              color: colors.onSurfaceVariant,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              'Chưa có từ nào trong bộ này.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Thêm từ đầu tiên để bắt đầu học.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
