import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_typography.dart';
import '../../domain/kanji_models.dart';
import '../providers/kanji_providers.dart';
import 'kanji_stroke_animator.dart';

Future<void> showKanjiAnalysis(BuildContext context, String? text) =>
    showDialog<void>(
      context: context,
      builder: (_) =>
          KanjiDetailDialog(characters: extractKanjiCharacters(text)),
    );

class KanjiDetailDialog extends StatelessWidget {
  const KanjiDetailDialog({
    required this.characters,
    this.initialIndex = 0,
    super.key,
  });
  final List<String> characters;
  final int initialIndex;
  @override
  Widget build(BuildContext context) =>
      _DetailBrowser(characters: characters, initialIndex: initialIndex);
}

class RadicalDetailDialog extends StatelessWidget {
  const RadicalDetailDialog({required this.radical, super.key});
  final Radical radical;
  @override
  Widget build(BuildContext context) =>
      _DetailBrowser(characters: const [], initialRadical: radical);
}

typedef _Entry = ({String? character, Radical? radical});

/// Điều hướng nội dung trong một dialog, không chồng vô hạn các dialog lên nhau.
class _DetailBrowser extends StatefulWidget {
  const _DetailBrowser({
    required this.characters,
    this.initialIndex = 0,
    this.initialRadical,
  });
  final List<String> characters;
  final int initialIndex;
  final Radical? initialRadical;
  @override
  State<_DetailBrowser> createState() => _DetailBrowserState();
}

class _DetailBrowserState extends State<_DetailBrowser> {
  late int _index;
  final _history = <_Entry>[];
  @override
  void initState() {
    super.initState();
    _index = widget.characters.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.characters.length - 1);
  }

  @override
  void didUpdateWidget(covariant _DetailBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characters != widget.characters ||
        oldWidget.initialRadical != widget.initialRadical) {
      _history.clear();
      _index = widget.characters.isEmpty
          ? 0
          : widget.initialIndex.clamp(0, widget.characters.length - 1);
    }
  }

  void _push(_Entry entry) => setState(() {
        // Giới hạn lịch sử; có thể đi lại giữa các chữ mà không tăng stack route.
        if (_history.length == 30) _history.removeAt(0);
        _history.add(entry);
      });

  @override
  Widget build(BuildContext context) {
    final entry = _history.isNotEmpty
        ? _history.last
        : (
            character:
                widget.characters.isEmpty ? null : widget.characters[_index],
            radical: widget.initialRadical
          );
    final colors = Theme.of(context).colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.sizeOf(context).height * .86,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Row(
                  children: [
                    if (_history.isNotEmpty)
                      IconButton(
                        tooltip: 'Quay lại',
                        onPressed: () => setState(() => _history.removeLast()),
                        icon: const Icon(Icons.arrow_back),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.radical != null
                            ? 'Chi tiết bộ thủ'
                            : 'Phân tích Hán tự',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng phân tích',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(color: colors.outlineVariant, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey('${entry.character}:${entry.radical?.id}'),
                  padding: const EdgeInsets.all(20),
                  child: entry.radical != null
                      ? _RadicalContent(
                          radical: entry.radical!,
                          onKanji: (char) =>
                              _push((character: char, radical: null)),
                        )
                      : entry.character != null
                          ? _KanjiContent(
                              character: entry.character!,
                              onRadical: (r) =>
                                  _push((character: null, radical: r)),
                            )
                          : const Text(
                              'Từ này không có ký tự Hán tự để phân tích.',
                            ),
                ),
              ),
              if (_history.isEmpty && widget.characters.length > 1)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed:
                            _index > 0 ? () => setState(() => _index--) : null,
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Trước'),
                      ),
                      Text('${_index + 1}/${widget.characters.length}'),
                      TextButton.icon(
                        onPressed: _index < widget.characters.length - 1
                            ? () => setState(() => _index++)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('Tiếp'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KanjiContent extends ConsumerWidget {
  const _KanjiContent({required this.character, required this.onRadical});
  final String character;
  final ValueChanged<Radical> onRadical;
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(kanjiDetailProvider(character)).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _Retry(
              message: 'Không tải được chi tiết Hán tự.',
              onRetry: () => ref.invalidate(kanjiDetailProvider(character)),
            ),
            data: (kanji) {
              if (kanji == null) {
                return Column(
                  children: [
                    _Character(character),
                    const Text(
                      'Chữ này chưa có trong danh mục 2.136 Jōyō. Các chữ được hỗ trợ vẫn có thể xem bằng Trước/Tiếp.',
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _Character(kanji.character)),
                  Center(
                    child: Text(
                      kanji.hanViet?.toUpperCase() ?? 'Chưa có âm Hán Việt',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        Chip(label: Text(kanji.gradeLabel)),
                        Chip(label: Text('${kanji.strokeCount} nét')),
                      ],
                    ),
                  ),
                  _TextSection(
                    'Âm On',
                    kanji.onyomi.isEmpty
                        ? 'Chưa có dữ liệu'
                        : kanji.onyomi.join(' · '),
                    japanese: kanji.onyomi.isNotEmpty,
                  ),
                  _TextSection(
                    'Âm Kun',
                    kanji.kunyomi.isEmpty
                        ? 'Chưa có dữ liệu'
                        : kanji.kunyomi.join(' · '),
                    japanese: kanji.kunyomi.isNotEmpty,
                  ),
                  _TextSection(
                    kanji.meaningVi == null
                        ? 'Nghĩa tiếng Anh (chưa có bản dịch)'
                        : 'Nghĩa tiếng Việt',
                    kanji.meaningVi ?? kanji.meaningEn,
                  ),
                  if (kanji.meaningVi != null && !kanji.translationReviewed)
                    const Text(
                      'Bản dịch đang chờ duyệt.',
                      style: TextStyle(fontSize: 12),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Thứ tự nét',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Center(child: KanjiStrokeViewer(character: character)),
                  const SizedBox(height: 20),
                  Text(
                    'Thành phần cấu tạo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ref.watch(kanjiComponentsProvider(kanji.id)).when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => _Retry(
                          message: 'Không tải được thành phần.',
                          onRetry: () =>
                              ref.invalidate(kanjiComponentsProvider(kanji.id)),
                        ),
                        data: (components) => components.isEmpty
                            ? const Text('Chưa có dữ liệu thành phần.')
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: components
                                    .map(
                                      (c) => ActionChip(
                                        label: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: c.form,
                                                style: AppTypography.kanji(
                                                  context,
                                                  null,
                                                ),
                                              ),
                                              TextSpan(
                                                  text: ' ${c.radical.nameVi}',),
                                            ],
                                          ),
                                        ),
                                        onPressed: () => onRadical(c.radical),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                  const SizedBox(height: 12),
                  const Text(
                    'Các thành phần được nhận diện thuộc 214 bộ thủ; không phải mọi nét đều là một bộ thủ riêng.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              );
            },
          );
}

class _RadicalContent extends ConsumerWidget {
  const _RadicalContent({required this.radical, required this.onKanji});
  final Radical radical;
  final ValueChanged<String> onKanji;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(kanjiSnapshotProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _Character(radical.character)),
        Center(
          child: Text(
            radical.nameVi,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _TextSection('Ý nghĩa', radical.meaningVi),
        _TextSection('Số nét của dạng gốc', '${radical.strokeCount}'),
        if (radical.variants.isNotEmpty)
          _TextSection(
            'Các biến thể',
            radical.variants.join(' · '),
            japanese: true,
          ),
        if (radical.positions.isNotEmpty)
          _TextSection('Vị trí thường gặp', radical.positions.join(' · ')),
        const SizedBox(height: 16),
        Text(
          'Trong thư viện của bạn',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        snapshot.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => _Retry(
            message: 'Không tải được thống kê thư viện.',
            onRetry: () => ref.invalidate(kanjiSnapshotProvider),
          ),
          data: (data) {
            if (data.overview == null) {
              return const Text(
                'Chưa có thống kê. Mở tab Hán tự và bấm Cập nhật thống kê.',
              );
            }
            final matches = data.radicals.where((r) => r.id == radical.id);
            final count = matches.isEmpty ? 0 : matches.first.count;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count lần xuất hiện trong bản thống kê gần nhất.'),
                const SizedBox(height: 10),
                ref.watch(radicalKanjiIdsProvider(radical.id)).when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => _Retry(
                        message: 'Không tải được Kanji liên quan.',
                        onRetry: () => ref.invalidate(
                          radicalKanjiIdsProvider(radical.id),
                        ),
                      ),
                      data: (ids) {
                        final kanji = data.kanji
                            .where((k) => ids.contains(k.id))
                            .toList();
                        if (kanji.isEmpty) {
                          return const Text(
                            'Chưa gặp bộ này trong thư viện.',
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: kanji
                              .map(
                                (k) => ActionChip(
                                  label: Text(
                                    '${k.character} · ${k.count}',
                                    style: AppTypography.kanji(context, null),
                                  ),
                                  onPressed: () => onKanji(k.character),
                                ),
                              )
                              .toList(),
                        );
                      },
                    ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Character extends StatelessWidget {
  const _Character(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.kanji(context, null, fontSize: 76));
}

class _TextSection extends StatelessWidget {
  const _TextSection(this.label, this.value, {this.japanese = false});
  final String label, value;
  final bool japanese;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              value,
              style: japanese
                  ? AppTypography.japanese(
                      context,
                      null,
                      fontSize: 17,
                      height: 1.5,
                    )
                  : const TextStyle(fontSize: 17, height: 1.5),
            ),
          ],
        ),
      );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(message),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      );
}
