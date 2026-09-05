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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (previous?.overview case final overview?) ...[
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          Text(
                            '${overview.kanjiCount} Hán tự',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${overview.radicalCount} bộ thủ',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cập nhật: ${DateFormat('HH:mm dd/MM/yyyy').format(overview.calculatedAt.toLocal())} · ${overview.vocabScanned} từ đã quét',
                      ),
                      if (overview.unsupportedCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${overview.unsupportedCount} ký tự Hán tự ngoài danh mục Jōyō chưa được hỗ trợ.',
                          ),
                        ),
                    ] else
                      const Text(
                        'Thống kê Hán tự từ thư viện từ vựng của bạn.',
                      ),
                    if (previous?.fromCache == true)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Đang xem bản thống kê đã lưu trên thiết bị.',
                        ),
                      ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: refresh.isLoading
                          ? null
                          : () =>
                              ref.read(kanjiRefreshProvider.notifier).refresh(),
                      icon: refresh.isLoading
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(
                        refresh.isLoading
                            ? 'Đang thống kê…'
                            : 'Cập nhật thống kê',
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Số liệu chỉ đổi khi bạn bấm cập nhật.',
                      style: TextStyle(fontSize: 12),
                    ),
                    if (refresh.hasError)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'Chưa cập nhật được thống kê. Kiểm tra kết nối và thử lại.',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: TabBar(tabs: [Tab(text: 'Hán tự'), Tab(text: 'Bộ thủ')]),
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
                  data.radicals.isEmpty
                      ? const _Empty(
                          'Chưa có bộ thủ',
                          'Bộ thủ sẽ xuất hiện khi thư viện có Hán tự được hỗ trợ.',
                        )
                      : RadicalGridView(items: data.radicals),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
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
  final List<Radical> items;
  @override
  Widget build(BuildContext context) => _grid(items.length, (context, index) {
        final item = items[index];
        return _GlyphTile(
          character: item.character,
          label: item.nameVi,
          count: item.count,
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => RadicalDetailDialog(radical: item),
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
  });
  final String character, label;
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$character, $label, $count lần xuất hiện',
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
