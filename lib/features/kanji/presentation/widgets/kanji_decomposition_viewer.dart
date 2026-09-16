import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_typography.dart';
import '../../data/kanji_stroke_service.dart';
import '../../domain/kanji_decomposition.dart';
import '../../domain/kanji_models.dart';
import '../providers/kanji_providers.dart';
import 'kanji_section_heading.dart';
import 'kanji_stroke_animator.dart';

/// Vùng hình cố định và nội dung phân tích cuộn, dùng chung SVG của chữ gốc.
class KanjiDecompositionViewer extends ConsumerWidget {
  const KanjiDecompositionViewer({
    required this.character,
    required this.hanVietLabel,
    required this.details,
    this.onRadicalForm,
    super.key,
  });
  final String character, hanVietLabel;
  final Widget details;
  final ValueChanged<RadicalForm>? onRadicalForm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = character.runes.single;
    final decomposition = ref.watch(kanjiDecompositionProvider(id));
    final strokes = ref.watch(kanjiStrokesProvider(character));
    final tree = decomposition.valueOrNull;
    Future<void> retry() async {
      ref.invalidate(kanjiDecompositionProvider(id));
      ref.invalidate(kanjiOccurrencesProvider(id));
      ref.invalidate(kanjiDecompositionMeaningsProvider(id));
      final service = await ref.read(kanjiStrokeServiceProvider.future);
      await service.invalidate(character);
      ref.invalidate(kanjiStrokesProvider(character));
    }

    if (tree == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (decomposition.isLoading) const LinearProgressIndicator(),
            if (!decomposition.isLoading) ...[
              const Text('Đang hiển thị phân tích cơ bản'),
              TextButton(
                onPressed: retry,
                child: const Text('Chưa tải được cây thành phần. Thử lại'),
              ),
            ],
            const KanjiSectionHeading('Thứ tự nét'),
            const SizedBox(height: 12),
            KanjiStrokeViewer(character: character, hanVietLabel: hanVietLabel),
            const SizedBox(height: 16),
            details,
          ],
        ),
      );
    }
    final meanings = ref.watch(kanjiDecompositionMeaningsProvider(id));
    return KanjiDecompositionPanel(
      key: ValueKey(character),
      tree: tree,
      document: strokes.valueOrNull,
      strokesLoading: strokes.isLoading,
      hanVietLabel: hanVietLabel,
      meanings: meanings.valueOrNull ?? const {},
      meaningsLoading: meanings.isLoading,
      meaningsError: meanings.hasError,
      onRetryMeanings: () =>
          ref.invalidate(kanjiDecompositionMeaningsProvider(id)),
      onRetry: retry,
      details: details,
      onRadicalForm: onRadicalForm,
    );
  }
}

class KanjiDecompositionPanel extends StatefulWidget {
  const KanjiDecompositionPanel({
    required this.tree,
    required this.hanVietLabel,
    this.document,
    this.strokesLoading = false,
    this.meanings = const {},
    this.meaningsLoading = false,
    this.meaningsError = false,
    this.onRetryMeanings,
    this.onRetry,
    this.details = const SizedBox.shrink(),
    this.onRadicalForm,
    super.key,
  });

  final KanjiDecomposition tree;
  final StrokeDocument? document;
  final String hanVietLabel;
  final bool strokesLoading, meaningsLoading, meaningsError;
  final Map<String, Kanji> meanings;
  final VoidCallback? onRetry, onRetryMeanings;
  final Widget details;
  final ValueChanged<RadicalForm>? onRadicalForm;

  @override
  State<KanjiDecompositionPanel> createState() =>
      _KanjiDecompositionPanelState();
}

class _KanjiDecompositionPanelState extends State<KanjiDecompositionPanel> {
  final _selection = KanjiDecompositionSelection();
  final _rowKeys = <String, GlobalKey>{};

  bool get _matching {
    final document = widget.document;
    return document != null &&
        document.kanjivgCommit == widget.tree.kanjivgCommit &&
        document.strokeIds.length == widget.tree.root.strokeIds.length &&
        document.strokeIds.toSet().length == document.strokeCount &&
        document.strokeIds.toSet().containsAll(widget.tree.root.strokeIds);
  }

  @override
  void didUpdateWidget(covariant KanjiDecompositionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tree != widget.tree) {
      _selection.clear();
      _rowKeys.clear();
    }
  }

  void _select(KanjiDecompositionNode node, int depth) {
    setState(() => _selection.select(node, depth));
    if (_selection.selected != node || node.children.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _selection.selected != node) return;
      final rowContext = _rowKeys[node.id]?.currentContext;
      if (rowContext == null) return;
      Scrollable.ensureVisible(
        rowContext,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selection.selected;
    final root = widget.tree.root;
    final document = widget.document;
    final levels = [root, ..._selection.branch];
    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const KanjiSectionHeading('Thứ tự nét'),
          const SizedBox(height: 8),
          if (document != null)
            KanjiStrokeAnimator(
              document: document,
              components: _matching
                  ? root.descendants
                      .map((n) => n.asOccurrence(widget.tree.kanjivgCommit))
                      .toList()
                  : const [],
              controlledSelection: true,
              selectedComponentId: selected?.id,
              showComponents: false,
              hanVietLabel: widget.hanVietLabel,
            )
          else ...[
            SizedBox(
              height: MediaQuery.sizeOf(context).height < 600 ? 144 : 200,
              child: Center(
                child: widget.strokesLoading
                    ? const CircularProgressIndicator()
                    : Text(
                        root.form ?? '',
                        style: AppTypography.kanji(
                          context,
                          null,
                          fontSize: 76,
                        ),
                      ),
              ),
            ),
            Text(
              widget.hanVietLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
          if (selected != null || _selection.branch.isNotEmpty)
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected == null
                        ? 'Đang xem cấu tạo'
                        : 'Đang chọn: ${selected.label.isEmpty ? selected.typeLabel : selected.label}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _matching ? _red(context) : null,
                      fontFamilyFallback: [
                        AppTypography.fontChoiceFor(context).fontFamily,
                        ...AppTypography.japaneseFontFamilyFallback,
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () => setState(_selection.clear),
                    child: const Text('Về toàn chữ'),
                  ),
                ),
              ],
            ),
          const Divider(height: 12),
        ],
      ),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_matching && !widget.strokesLoading) ...[
          Text(
            document == null
                ? 'Chưa tải được thứ tự nét. Bạn vẫn có thể xem cây thành phần.'
                : 'Dữ liệu thành phần và nét chưa khớp. Chưa thể tô nét.',
          ),
          TextButton(
            onPressed: widget.onRetry,
            child: const Text('Tải lại nét'),
          ),
        ],
        for (var depth = 0; depth < levels.length; depth++)
          _level(context, levels[depth], depth),
        if (selected?.kind == KanjiComponentKind.radical)
          Text(
            '${selected!.label} · ${selected.radicalMeaning ?? 'Chưa có thông tin nghĩa'}',
            style: TextStyle(
              fontFamilyFallback: [
                AppTypography.fontChoiceFor(context).fontFamily,
                ...AppTypography.japaneseFontFamilyFallback,
              ],
            ),
          ),
        if (selected?.radicalForm != null && widget.onRadicalForm != null)
          TextButton(
            onPressed: () => widget.onRadicalForm!(selected.radicalForm!),
            child: Text(
              'Chi tiết bộ thủ ${selected!.label}',
              style: TextStyle(
                fontFamilyFallback: [
                  AppTypography.fontChoiceFor(context).fontFamily,
                  ...AppTypography.japaneseFontFamilyFallback,
                ],
              ),
            ),
          ),
        if (selected != null &&
            selected.children.isEmpty &&
            selected.kind == KanjiComponentKind.kanji) ...[
          _meaning(selected),
          const Text('Chưa có phân tích sâu hơn trong dữ liệu nguồn.'),
        ],
        const SizedBox(height: 16),
        widget.details,
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // Preserve a usable scroll area with extreme text scaling/short windows.
        final compact = constraints.maxHeight < 450 ||
            MediaQuery.textScalerOf(context).scale(16) > 24;
        if (compact) {
          return SingleChildScrollView(
            child: Column(
              children: [
                header,
                Padding(padding: const EdgeInsets.all(16), child: content),
              ],
            ),
          );
        }
        return Column(
          children: [
            header,
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: content,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _level(
    BuildContext context,
    KanjiDecompositionNode parent,
    int depth,
  ) {
    final nodes =
        parent.children.isEmpty && depth == 0 ? [parent] : parent.children;
    return Padding(
      key: _rowKeys.putIfAbsent(parent.id, GlobalKey.new),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (depth > 0) ...[
            const Divider(height: 16),
            _meaning(parent),
          ],
          KanjiSectionHeading(
            'Thành phần của ${parent.form ?? parent.typeLabel}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final node in nodes)
                _NodeChip(
                  node: node,
                  document: _matching ? widget.document : null,
                  hanVietName: widget.meanings[node.form]?.hanViet,
                  selected: _selection.selected?.id == node.id,
                  onPressed: () => _select(node, depth),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _meaning(KanjiDecompositionNode node) {
    final kanji = widget.meanings[node.form];
    final text = widget.meaningsLoading
        ? 'Đang tải thông tin nghĩa…'
        : kanji == null
            ? 'Chưa có thông tin nghĩa'
            : [kanji.hanViet?.toUpperCase(), kanji.meaningVi ?? kanji.meaningEn]
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${node.form ?? ''} · $text',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamilyFallback: [
                AppTypography.fontChoiceFor(context).fontFamily,
                ...AppTypography.japaneseFontFamilyFallback,
              ],
            ),
          ),
          if (widget.meaningsError)
            TextButton(
              onPressed: widget.onRetryMeanings,
              child: const Text('Tải lại nghĩa'),
            ),
        ],
      ),
    );
  }
}

Color _red(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFD32F2F);

class _NodeChip extends StatelessWidget {
  const _NodeChip({
    required this.node,
    required this.document,
    required this.hanVietName,
    required this.selected,
    required this.onPressed,
  });
  final KanjiDecompositionNode node;
  final StrokeDocument? document;
  final String? hanVietName;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = switch (node.kind) {
      KanjiComponentKind.kanji =>
        dark ? const Color(0xFFB5B9FF) : const Color(0xFF4F46B5),
      KanjiComponentKind.radical =>
        dark ? const Color(0xFF75D9CD) : const Color(0xFF006B60),
      _ => colors.onSurfaceVariant,
    };
    final preview = document != null;
    final ink = selected ? _red(context) : accent;
    final name = switch (node.kind) {
      KanjiComponentKind.radical => node.radicalName ?? node.form ?? 'Bộ thủ',
      KanjiComponentKind.supplementary => 'Nét phụ',
      KanjiComponentKind.kanji => hanVietName?.trim() ?? '',
    };
    final semanticName = node.kind == KanjiComponentKind.supplementary
        ? 'Nét phụ'
        : '${node.form ?? ''} ${name.isEmpty ? 'Thành phần chưa có tên' : name}'
            .trim();
    return Semantics(
      button: true,
      selected: selected,
      label:
          '$semanticName${node.children.isNotEmpty ? ', mở thành phần con' : ''}',
      child: OutlinedButton(
        key: ValueKey('tree-component:${node.id}'),
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: accent.withValues(alpha: dark ? .13 : .07),
          side: BorderSide(
            color: selected ? ink : accent.withValues(alpha: .6),
            width: selected ? 2 : 1,
          ),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (preview)
                  SizedBox.square(
                    dimension: 28,
                    child: document!.supportsAnimation
                        ? CustomPaint(
                            painter: KanjiStrokePainter(
                              document!,
                              document!.strokeCount.toDouble(),
                              ink,
                              colors.outlineVariant,
                              onlyStrokeIds: node.strokeIds.toSet(),
                              drawGrid: false,
                              fitToStrokeBounds: true,
                              strokeWidth: 5,
                              maxScale: 36 / document!.viewBox.longestSide,
                            ),
                          )
                        : SvgPicture.string(
                            document!.staticSvgAt(
                              0,
                              ink: ink,
                              onlyStrokeIds: node.strokeIds.toSet(),
                            ),
                          ),
                  )
                else if (node.form != null &&
                    node.kind != KanjiComponentKind.supplementary)
                  Text(
                    node.form!,
                    style: AppTypography.kanji(
                      context,
                      null,
                      fontSize: 24,
                      color: ink,
                    ),
                  ),
                if (name.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(name),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
