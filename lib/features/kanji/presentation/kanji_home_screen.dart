import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_typography.dart';
import '../domain/kanji_models.dart';
import 'providers/kanji_providers.dart';
import 'widgets/kanji_detail_dialog.dart';

class KanjiHomeScreen extends ConsumerWidget {
  const KanjiHomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(kanjiSnapshotProvider);
    final refresh = ref.watch(kanjiRefreshProvider);
    final previous = snapshot.valueOrNull;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Hán tự & Bộ thủ')),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: _KanjiStatsOverview(
                  snapshot: previous,
                  refresh: refresh,
                  onRefresh: () =>
                      ref.read(kanjiRefreshProvider.notifier).refresh(),
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedTabBarDelegate(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                tabBar: const TabBar(
                  tabs: [Tab(text: 'Hán tự'), Tab(text: 'Bộ thủ')],
                ),
              ),
            ),
          ],
          body: snapshot.when(
            skipLoadingOnRefresh: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Không tải được thống kê.'),
                  TextButton(
                    onPressed: () => ref.invalidate(kanjiSnapshotProvider),
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            ),
            data: (data) {
              if (data.overview == null) {
                return const _Empty(
                  'Chưa có thống kê',
                  'Bấm Cập nhật thống kê để xem Hán tự và bộ thủ trong thư viện.',
                );
              }
              return TabBarView(
                children: [
                  data.kanji.isEmpty
                      ? const _Empty(
                          'Chưa có Hán tự',
                          'Thêm từ có Hán tự được hỗ trợ vào thư viện rồi cập nhật thống kê.',
                        )
                      : KanjiGridView(items: data.kanji),
                  data.radicalForms.isEmpty
                      ? const _Empty(
                          'Chưa có bộ thủ',
                          'Bộ thủ sẽ xuất hiện khi thư viện có Hán tự được hỗ trợ.',
                        )
                      : RadicalGridView(items: data.radicalForms),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedTabBarDelegate({
    required this.tabBar,
    required this.backgroundColor,
  });

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) =>
      Material(
        color: backgroundColor,
        elevation: overlapsContent ? 2 : 0,
        shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: .2),
        child: tabBar,
      );

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar ||
      oldDelegate.backgroundColor != backgroundColor;
}

class _KanjiStatsOverview extends StatelessWidget {
  const _KanjiStatsOverview({
    required this.snapshot,
    required this.refresh,
    required this.onRefresh,
  });

  final KanjiSnapshot? snapshot;
  final AsyncValue<void> refresh;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final overview = snapshot?.overview;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (overview != null) ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = (constraints.maxWidth - 10) / 2;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatMetric(
                        width: width,
                        value: overview.kanjiCount,
                        label: 'Hán tự',
                        icon: Icons.translate_rounded,
                        background: colors.primaryContainer,
                        foreground: colors.onPrimaryContainer,
                      ),
                      _StatMetric(
                        width: width,
                        value: overview.radicalCount,
                        label: 'Bộ thủ',
                        icon: Icons.account_tree_outlined,
                        background: colors.secondaryContainer,
                        foreground: colors.onSecondaryContainer,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _MetadataRow(
                icon: Icons.schedule_rounded,
                text:
                    'Cập nhật ${DateFormat('HH:mm · dd/MM/yyyy').format(overview.calculatedAt.toLocal())}',
              ),
              if (overview.needsComponentUpdate) ...[
                const SizedBox(height: 12),
                _StatusBanner(
                  icon: Icons.sync_problem_rounded,
                  message:
                      'Quy tắc phân tích đã thay đổi. Cập nhật thống kê để đồng bộ.',
                  background: colors.tertiaryContainer,
                  foreground: colors.onTertiaryContainer,
                ),
              ],
              if (overview.unsupportedCount > 0) ...[
                const SizedBox(height: 10),
                _StatusBanner(
                  icon: Icons.info_outline_rounded,
                  message:
                      '${overview.unsupportedCount} ký tự Hán tự ngoài danh mục Jōyō chưa được hỗ trợ.',
                  background: colors.surfaceContainerHighest,
                  foreground: colors.onSurfaceVariant,
                ),
              ],
            ] else
              Text(
                'Chưa có dữ liệu thống kê. Hãy cập nhật để khám phá các Hán tự và bộ thủ trong thư viện.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.4,
                    ),
              ),
            if (snapshot?.fromCache == true) ...[
              const SizedBox(height: 10),
              _StatusBanner(
                icon: Icons.cloud_off_outlined,
                message: 'Bạn đang xem dữ liệu đã lưu trên thiết bị.',
                background: colors.surfaceContainerHighest,
                foreground: colors.onSurfaceVariant,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: refresh.isLoading ? null : onRefresh,
                icon: refresh.isLoading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(
                  refresh.isLoading ? 'Đang thống kê…' : 'Cập nhật thống kê',
                ),
              ),
            ),
            if (refresh.hasError) ...[
              const SizedBox(height: 10),
              _StatusBanner(
                icon: Icons.error_outline_rounded,
                message:
                    'Chưa cập nhật được thống kê. Kiểm tra kết nối và thử lại.',
                background: colors.errorContainer,
                foreground: colors.onErrorContainer,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatMetric extends StatelessWidget {
  const _StatMetric({
    required this.width,
    required this.value,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final double width;
  final int value;
  final String label;
  final IconData icon;
  final Color background, foreground;

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$value $label',
        child: Container(
          width: width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$value',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.icon,
    required this.message,
    required this.background,
    required this.foreground,
  });

  final IconData icon;
  final String message;
  final Color background, foreground;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 19, color: foreground),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foreground,
                      height: 1.35,
                    ),
              ),
            ),
          ],
        ),
      );
}

class KanjiGridView extends StatelessWidget {
  const KanjiGridView({required this.items, super.key});
  final List<Kanji> items;
  @override
  Widget build(BuildContext context) => _grid(items.length, (context, index) {
        final item = items[index];
        return _GlyphTile(
          character: item.character,
          label: item.hanViet ?? 'Chưa có âm',
          count: item.count,
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => KanjiDetailDialog(characters: [item.character]),
          ),
        );
      });
}

class RadicalGridView extends StatelessWidget {
  const RadicalGridView({required this.items, super.key});
  final List<RadicalForm> items;
  @override
  Widget build(BuildContext context) => _grid(items.length, (context, index) {
        final item = items[index];
        return _GlyphTile(
          character: item.form,
          label: item.radical.nameVi,
          count: item.count,
          semanticKind: item.isOriginal ? 'dạng gốc' : 'biến thể',
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => RadicalDetailDialog(radicalForm: item),
          ),
        );
      });
}

Widget _grid(int count, IndexedWidgetBuilder builder) => GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 160,
        mainAxisExtent: 146,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: builder,
    );

class _GlyphTile extends StatelessWidget {
  const _GlyphTile({
    required this.character,
    required this.label,
    required this.count,
    required this.onTap,
    this.semanticKind,
  });
  final String character, label;
  final String? semanticKind;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: [
          character,
          label,
          if (semanticKind != null) semanticKind!,
          '$count lần xuất hiện',
        ].join(', '),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 22, 6, 8),
                    child: Column(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              character,
                              style: AppTypography.kanji(
                                context,
                                null,
                                fontSize: 52,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 7,
                  right: 7,
                  child: Badge(label: Text('$count')),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.title, this.message);
  final String title, message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_stories_outlined, size: 44),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
}
