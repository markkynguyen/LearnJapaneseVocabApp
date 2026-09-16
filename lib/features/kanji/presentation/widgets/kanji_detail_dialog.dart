import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_models.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/kanji_models.dart';
import '../../domain/kanji_vocabulary_readings.dart';
import '../providers/kanji_providers.dart';
import '../radical_display_groups.dart';
import 'kanji_section_heading.dart';
import 'kanji_decomposition_viewer.dart';

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
  const RadicalDetailDialog({
    this.radicalForm,
    this.displayItem,
    super.key,
  }) : assert(radicalForm != null || displayItem != null);

  final RadicalForm? radicalForm;
  final RadicalDisplayItem? displayItem;

  @override
  Widget build(BuildContext context) => _DetailBrowser(
        characters: const [],
        initialRadicalItem:
            displayItem ?? radicalDisplayItemForForm(radicalForm!),
      );
}

typedef _Entry = ({String? character, RadicalDisplayItem? radicalItem});

/// Điều hướng nội dung trong một dialog, không chồng vô hạn các dialog lên nhau.
class _DetailBrowser extends StatefulWidget {
  const _DetailBrowser({
    required this.characters,
    this.initialIndex = 0,
    this.initialRadicalItem,
  });
  final List<String> characters;
  final int initialIndex;
  final RadicalDisplayItem? initialRadicalItem;
  @override
  State<_DetailBrowser> createState() => _DetailBrowserState();
}

class _DetailBrowserState extends State<_DetailBrowser> {
  late int _index;
  int _contentGeneration = 0;
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
        oldWidget.initialRadicalItem != widget.initialRadicalItem ||
        oldWidget.initialIndex != widget.initialIndex) {
      _contentGeneration++;
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
            radicalItem: widget.initialRadicalItem
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
                        entry.radicalItem != null
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
                child: KeyedSubtree(
                  key: ValueKey(
                    '$_contentGeneration:$_index:${_history.length}:${entry.character}:${entry.radicalItem?.radical.id}:${entry.radicalItem?.form}',
                  ),
                  child: entry.radicalItem != null
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _RadicalContent(
                            displayItem: entry.radicalItem!,
                            onRadicalForm: (form) => _push(
                              (
                                character: null,
                                radicalItem: radicalDisplayItemForForm(form),
                              ),
                            ),
                            onKanji: (char) => _push(
                              (character: char, radicalItem: null),
                            ),
                          ),
                        )
                      : entry.character != null
                          ? _KanjiContent(
                              character: entry.character!,
                              onRadicalForm: (form) => _push(
                                (
                                  character: null,
                                  radicalItem: radicalDisplayItemForForm(form),
                                ),
                              ),
                            )
                          : const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Từ này không có ký tự Hán tự để phân tích.',
                              ),
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
  const _KanjiContent({required this.character, required this.onRadicalForm});
  final String character;
  final ValueChanged<RadicalForm> onRadicalForm;
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
                return const Text(
                  'Chữ này chưa có trong danh mục 2.136 Jōyō. Các chữ được hỗ trợ vẫn có thể xem bằng Trước/Tiếp.',
                );
              }
              return KanjiDecompositionViewer(
                character: character,
                onRadicalForm: onRadicalForm,
                hanVietLabel:
                    kanji.hanViet?.toUpperCase() ?? 'Chưa có âm Hán Việt',
                details: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TextSection(
                      kanji.meaningVi == null
                          ? 'Nghĩa tiếng Anh (chưa có bản dịch)'
                          : 'Nghĩa tiếng Việt',
                      kanji.meaningVi ?? kanji.meaningEn,
                    ),
                    _KanjiVocabularyReadings(character: character),
                  ],
                ),
              );
            },
          );
}

class _RadicalContent extends ConsumerWidget {
  const _RadicalContent({
    required this.displayItem,
    required this.onRadicalForm,
    required this.onKanji,
  });
  final RadicalDisplayItem displayItem;
  final ValueChanged<RadicalForm> onRadicalForm;
  final ValueChanged<String> onKanji;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(kanjiSnapshotProvider);
    final radical = displayItem.radical;
    final familyForms = displayItem.isGrouped
        ? const <RadicalForm>[]
        : _familyForms(displayItem.radicalForm, snapshot.valueOrNull);
    final currentForm = displayItem.isGrouped
        ? displayItem.radicalForm
        : familyForms.firstWhere(
            (item) => item.form == displayItem.form,
            orElse: () => displayItem.radicalForm,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: _Character(currentForm.form)),
        Center(
          child: Text(
            radical.nameVi,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _TextSection('Ý nghĩa', radical.meaningVi),
        _TextSection('Số nét của dạng gốc', '${radical.strokeCount}'),
        if (!displayItem.isGrouped && radical.variants.isNotEmpty)
          _RadicalFamilyNavigation(
            forms: familyForms,
            selectedForm: currentForm.form,
            onSelected: onRadicalForm,
          ),
        if (radical.positions.isNotEmpty)
          _TextSection('Vị trí thường gặp', radical.positions.join(' · ')),
        const SizedBox(height: 16),
        const KanjiSectionHeading('Trong thư viện của bạn'),
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
            final currentDisplayItem = displayItem.isGrouped
                ? _displayItemFromSnapshot(data, displayItem)
                : displayItem;
            final count = currentDisplayItem.isGrouped
                ? currentDisplayItem.count
                : _formCount(data, radical, currentForm);
            final key = RadicalFormsKey(
              radicalId: radical.id,
              forms: currentDisplayItem.memberForms,
            );
            final relatedKanji = currentDisplayItem.isGrouped
                ? ref.watch(radicalKanjiIdsForFormsProvider(key))
                : ref.watch(
                    radicalKanjiIdsProvider(
                      (
                        radicalId: radical.id,
                        form: currentForm.form,
                      ),
                    ),
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count lần xuất hiện trong bản thống kê gần nhất.'),
                const SizedBox(height: 10),
                if (data.overview!.needsComponentUpdate)
                  const Text(
                    'Quy tắc phân tích đã thay đổi. Cập nhật thống kê ở tab Hán tự để xem Kanji liên quan.',
                  )
                else
                  relatedKanji.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => _Retry(
                      message: 'Không tải được Kanji liên quan.',
                      onRetry: () {
                        if (currentDisplayItem.isGrouped) {
                          ref.invalidate(
                            radicalKanjiIdsForFormsProvider(key),
                          );
                        } else {
                          ref.invalidate(
                            radicalKanjiIdsProvider(
                              (
                                radicalId: radical.id,
                                form: currentForm.form,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    data: (ids) {
                      final kanji =
                          data.kanji.where((k) => ids.contains(k.id)).toList();
                      if (kanji.isEmpty) {
                        return const Text(
                          'Chưa gặp dạng này trong thư viện.',
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

RadicalDisplayItem _displayItemFromSnapshot(
  KanjiSnapshot snapshot,
  RadicalDisplayItem fallback,
) {
  for (final item in radicalDisplayItems(snapshot.radicalForms)) {
    if (item.isGrouped &&
        item.radical.id == fallback.radical.id &&
        item.form == fallback.form) {
      return item;
    }
  }
  return fallback;
}

int _formCount(KanjiSnapshot snapshot, Radical radical, RadicalForm form) {
  final matches = snapshot.radicalForms.where(
    (item) => item.radical.id == radical.id && item.form == form.form,
  );
  return matches.isEmpty ? form.count : matches.first.count;
}

List<RadicalForm> _familyForms(
  RadicalForm selected,
  KanjiSnapshot? snapshot,
) {
  final known = <String, RadicalForm>{
    for (final item in snapshot?.radicalForms ?? const <RadicalForm>[])
      if (item.radical.id == selected.radical.id) item.form: item,
  };
  known.putIfAbsent(selected.form, () => selected);
  final radical = selected.radical;
  final forms = [radical.character, ...radical.variants];
  return [
    for (var index = 0; index < forms.length; index++)
      known[forms[index]] ??
          RadicalForm(
            radical: radical,
            form: forms[index],
            count: 0,
            familyCount: selected.familyCount,
            isOriginal: index == 0,
            formOrder: index,
          ),
  ];
}

class _RadicalFamilyNavigation extends StatelessWidget {
  const _RadicalFamilyNavigation({
    required this.forms,
    required this.selectedForm,
    required this.onSelected,
  });

  final List<RadicalForm> forms;
  final String selectedForm;
  final ValueChanged<RadicalForm> onSelected;

  @override
  Widget build(BuildContext context) {
    final original = forms.first;
    final variants = forms.skip(1).toList();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const KanjiSectionHeading('Dạng gốc'),
          const SizedBox(height: 8),
          _RadicalFormBox(
            item: original,
            selected: original.form == selectedForm,
            onPressed: () => onSelected(original),
          ),
          if (variants.isNotEmpty) ...[
            const SizedBox(height: 14),
            const KanjiSectionHeading('Các biến thể'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in variants)
                  _RadicalFormBox(
                    item: item,
                    selected: item.form == selectedForm,
                    onPressed: () => onSelected(item),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RadicalFormBox extends StatelessWidget {
  const _RadicalFormBox({
    required this.item,
    required this.selected,
    required this.onPressed,
  });

  final RadicalForm item;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final borderColor = selected ? colors.primary : colors.outlineVariant;
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${item.form}, ${item.isOriginal ? 'dạng gốc' : 'biến thể'}, ${item.count} lần xuất hiện',
      child: Material(
        key: ValueKey('radical-form:${item.radical.id}:${item.form}'),
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderColor, width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 76, minHeight: 58),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.form,
                    style: AppTypography.kanji(
                      context,
                      Theme.of(context).textTheme.titleLarge,
                      color: selected
                          ? colors.onPrimaryContainer
                          : colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected
                              ? colors.onPrimaryContainer
                              : colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KanjiVocabularyReadings extends ConsumerWidget {
  const _KanjiVocabularyReadings({required this.character});

  final String character;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(kanjiVocabularyGroupsProvider(character)).when(
            loading: () => const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đang tải từ vựng trong Thư viện...'),
                SizedBox(height: 8),
                LinearProgressIndicator(),
              ],
            ),
            error: (_, __) => _Retry(
              message: 'Không tải được từ vựng trong Thư viện.',
              onRetry: () =>
                  ref.invalidate(kanjiVocabularyGroupsProvider(character)),
            ),
            data: (groups) => Column(
              children: [
                _ReadingCategoryTile(
                  key: ValueKey('$character:on'),
                  title: 'Âm On',
                  count: groups.onyomiCount,
                  groups: groups.onyomi,
                ),
                const SizedBox(height: 10),
                _ReadingCategoryTile(
                  key: ValueKey('$character:kun'),
                  title: 'Âm Kun',
                  count: groups.kunyomiCount,
                  groups: groups.kunyomi,
                ),
                if (groups.unknown.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _UnknownReadingTile(
                    key: ValueKey('$character:unknown'),
                    vocabulary: groups.unknown,
                  ),
                ],
              ],
            ),
          );
}

class _ReadingCategoryTile extends StatelessWidget {
  const _ReadingCategoryTile({
    required this.title,
    required this.count,
    required this.groups,
    super.key,
  });

  final String title;
  final int count;
  final List<KanjiVocabularyReadingGroup> groups;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: false,
        maintainState: true,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: KanjiSectionHeading('$title ($count)', maxLines: 1),
        children: groups.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chưa có dữ liệu cách đọc.',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ),
              ]
            : [
                Divider(height: 1, color: colors.outlineVariant),
                for (var index = 0; index < groups.length; index++) ...[
                  _ReadingGroupTile(group: groups[index]),
                  if (index < groups.length - 1)
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: colors.outlineVariant,
                    ),
                ],
              ],
      ),
    );
  }
}

class _ReadingGroupTile extends StatelessWidget {
  const _ReadingGroupTile({required this.group});

  final KanjiVocabularyReadingGroup group;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        key: PageStorageKey('${group.type.name}:${group.reading}'),
        initiallyExpanded: false,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          '${group.reading} (${group.vocabulary.length})',
          locale: AppTypography.japaneseLocale,
          style: AppTypography.japanese(
            context,
            Theme.of(context).textTheme.titleSmall,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: group.vocabulary.isEmpty
            ? [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text('Chưa có từ vựng trong Thư viện.'),
                  ),
                ),
              ]
            : [
                for (var index = 0;
                    index < group.vocabulary.length;
                    index++) ...[
                  _VocabularyReadingRow(vocab: group.vocabulary[index]),
                  if (index < group.vocabulary.length - 1)
                    const Divider(height: 16),
                ],
              ],
      );
}

class _UnknownReadingTile extends StatelessWidget {
  const _UnknownReadingTile({required this.vocabulary, super.key});

  final List<VocabularyEntry> vocabulary;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: false,
          shape: const Border(),
          collapsedShape: const Border(),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: KanjiSectionHeading(
            'Chưa xác định (${vocabulary.length})',
            maxLines: 1,
          ),
          children: [
            for (var index = 0; index < vocabulary.length; index++) ...[
              _VocabularyReadingRow(vocab: vocabulary[index]),
              if (index < vocabulary.length - 1) const Divider(height: 16),
            ],
          ],
        ),
      );
}

class _VocabularyReadingRow extends StatelessWidget {
  const _VocabularyReadingRow({required this.vocab});

  final VocabularyEntry vocab;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final kanji = vocab.kanji?.trim();
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              kanji == null || kanji.isEmpty ? vocab.kana.trim() : kanji,
              locale: AppTypography.japaneseLocale,
              style: AppTypography.kanji(
                context,
                null,
                color: colors.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              vocab.kana.trim(),
              locale: AppTypography.japaneseLocale,
              style: AppTypography.japanese(
                context,
                null,
                color: colors.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vocab.meaning.trim(),
              style: TextStyle(color: colors.onSurface, height: 1.35),
            ),
          ],
        ),
      ),
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
  const _TextSection(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KanjiSectionHeading(label),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 17, height: 1.5),
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
