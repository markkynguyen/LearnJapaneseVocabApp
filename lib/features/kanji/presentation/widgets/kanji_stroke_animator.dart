import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/kanji_stroke_service.dart';
import '../../domain/kanji_models.dart';
import '../providers/kanji_providers.dart';
import '../../../../core/theme/app_typography.dart';
import 'kanji_section_heading.dart';

List<KanjiComponentOccurrence> orderKanjiComponents(
  Iterable<KanjiComponentOccurrence> components,
) {
  final ordered = List<KanjiComponentOccurrence>.of(components);
  ordered.sort(
    (a, b) => a.sortOrder != b.sortOrder
        ? a.sortOrder.compareTo(b.sortOrder)
        : a.id.compareTo(b.id),
  );
  return ordered;
}

const _componentChipHeight = 48.0;
const _radicalGlyphSize = 18.0;
const _supplementaryStrokePreviewSize = 28.0;
const _supplementaryStrokeReferenceSize = _radicalGlyphSize * 2;
const _supplementaryStrokeWidth = 6.0;

class KanjiStrokeViewer extends ConsumerWidget {
  const KanjiStrokeViewer({
    required this.character,
    required this.hanVietLabel,
    super.key,
  });
  final String character;
  final String hanVietLabel;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occurrences =
        ref.watch(kanjiOccurrencesProvider(character.runes.single));
    final orderedOccurrences = orderKanjiComponents(
      occurrences.valueOrNull ?? const [],
    );
    final strokes = ref.watch(kanjiStrokesProvider(character));
    Future<void> retry() async {
      final service = await ref.read(kanjiStrokeServiceProvider.future);
      await service.invalidate(character);
      if (!context.mounted) return;
      ref.invalidate(kanjiOccurrencesProvider(character.runes.single));
      ref.invalidate(kanjiStrokesProvider(character));
    }

    final unavailableComponents = orderedOccurrences.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 20),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const KanjiSectionHeading('Thành phần'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final component in orderedOccurrences)
                        Chip(label: _ComponentLabel(component)),
                    ],
                  ),
                ],
              ),
            ),
          );
    return Column(
      children: [
        if (occurrences.isLoading) const LinearProgressIndicator(),
        if (occurrences.hasError)
          TextButton(
            onPressed: () => ref
                .invalidate(kanjiOccurrencesProvider(character.runes.single)),
            child: const Text('Không tải được thành phần. Thử lại'),
          ),
        strokes.when(
          data: (document) => KanjiStrokeAnimator(
            key: ValueKey(character),
            document: document,
            components: orderedOccurrences,
            hanVietLabel: hanVietLabel,
            onRetry: retry,
          ),
          loading: () => Column(
            children: [
              const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              ),
              _HanVietLabel(hanVietLabel),
              unavailableComponents,
            ],
          ),
          error: (_, __) => Column(
            children: [
              const Text(
                'Chưa tải được thứ tự nét nên chưa thể tô nét. Bạn vẫn có thể đọc nghĩa và thành phần.',
              ),
              TextButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tải lại nét'),
              ),
              _HanVietLabel(hanVietLabel),
              unavailableComponents,
            ],
          ),
        ),
      ],
    );
  }
}

class KanjiStrokeAnimator extends StatefulWidget {
  const KanjiStrokeAnimator({
    required this.document,
    this.components = const [],
    this.hanVietLabel,
    this.onRetry,
    this.controlledSelection = false,
    this.selectedComponentId,
    this.showComponents = true,
    super.key,
  });
  final StrokeDocument document;
  final List<KanjiComponentOccurrence> components;
  final String? hanVietLabel;
  final VoidCallback? onRetry;
  final bool controlledSelection, showComponents;
  final String? selectedComponentId;
  @override
  State<KanjiStrokeAnimator> createState() => _KanjiStrokeAnimatorState();
}

class _KanjiStrokeAnimatorState extends State<KanjiStrokeAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animated = false;
  bool _reduceMotion = false;
  int _step = 0;
  String? _selectedId;
  Set<String> get _highlighted => widget.components
      .where((c) => c.id == _selectedId && _canHighlight(c))
      .expand((c) => c.strokeIds)
      .toSet();
  bool _canHighlight(KanjiComponentOccurrence c) =>
      c.componentVersion == 3 &&
      c.kanjivgCommit == widget.document.kanjivgCommit &&
      c.strokeIds.isNotEmpty &&
      widget.document.strokeIds.every((id) => id.isNotEmpty) &&
      widget.document.strokeIds.toSet().length == widget.document.strokeCount &&
      c.strokeIds.every(widget.document.strokeIds.contains);
  void _select(KanjiComponentOccurrence c) => setState(() {
        _controller.stop();
        _animated = false;
        _step = 0;
        _selectedId = _selectedId == c.id ? null : c.id;
      });
  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedComponentId;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.document.strokeCount * 650),
    );
  }

  @override
  void didUpdateWidget(covariant KanjiStrokeAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) {
      _controller.stop();
      _controller.duration =
          Duration(milliseconds: widget.document.strokeCount * 650);
      _controller.value = 0;
      _step = 0;
      _selectedId = null;
      _animated = false;
    } else if (!widget.controlledSelection &&
        _selectedId != null &&
        !widget.components
            .any((c) => c.id == _selectedId && _canHighlight(c))) {
      _selectedId = null;
    }
    if (widget.controlledSelection &&
        (oldWidget.selectedComponentId != widget.selectedComponentId ||
            oldWidget.document != widget.document)) {
      _controller.stop();
      _animated = false;
      _step = 0;
      _selectedId = widget.selectedComponentId;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.stop();
      _animated = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderedComponents = orderKanjiComponents(widget.components);
    final total = widget.document.strokeCount;
    final colors = Theme.of(context).colorScheme;
    final red = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF6B6B)
        : const Color(0xFFD32F2F);
    return Column(
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Từng nét'),
              icon: Icon(Icons.gesture),
            ),
            ButtonSegment(
              value: true,
              label: Text('Tự vẽ'),
              icon: Icon(Icons.play_arrow),
            ),
          ],
          selected: {
            _animated,
          },
          onSelectionChanged: _reduceMotion ||
                  !widget.document.supportsAnimation ||
                  _selectedId != null
              ? null
              : (selected) {
                  setState(() => _animated = selected.single);
                  if (_animated) {
                    _controller.forward(from: 0);
                  } else {
                    _controller.stop();
                  }
                },
        ),
        if (_reduceMotion)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Đang bật giảm chuyển động.'),
          ),
        if (!widget.document.supportsAnimation)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('SVG này chỉ hỗ trợ xem từng nét.'),
          ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Column(
            children: [
              Semantics(
                label:
                    'Thứ tự viết ${_animated ? (_controller.value * total).ceil() : _step}/$total nét',
                image: true,
                child: SizedBox.square(
                  dimension:
                      MediaQuery.sizeOf(context).height < 600 ? 144 : 200,
                  child: !widget.document.supportsAnimation
                      ? SvgPicture.string(
                          widget.document.staticSvgAt(
                            _step,
                            highlighted: _highlighted,
                            ink: colors.primary,
                            highlight: red,
                          ),
                          errorBuilder: (context, error, stack) => const Center(
                            child: Text(
                              'Dữ liệu nét bị lỗi. Nghĩa và cách đọc vẫn dùng được.',
                            ),
                          ),
                        )
                      : CustomPaint(
                          painter: KanjiStrokePainter(
                            widget.document,
                            _animated
                                ? _controller.value * total
                                : (_step == 0
                                    ? total.toDouble()
                                    : _step.toDouble()),
                            colors.primary,
                            colors.outlineVariant,
                            highlightedStrokeIds: _highlighted,
                            highlightColor: red,
                          ),
                        ),
                ),
              ),
              if (_animated)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        _controller.isAnimating
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                      label:
                          Text(_controller.isAnimating ? 'Tạm dừng' : 'Phát'),
                      onPressed: () {
                        setState(() {
                          if (_controller.isAnimating) {
                            _controller.stop();
                          } else {
                            _controller.forward(
                              from: _controller.isCompleted ? 0 : null,
                            );
                          }
                        });
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.replay),
                      label: const Text('Vẽ lại'),
                      onPressed: () => setState(() {
                        _controller.forward(from: 0);
                      }),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (!_animated)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Nét trước',
                onPressed: _step > 0 && _selectedId == null
                    ? () => setState(() => _step--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Flexible(
                  child:
                      Text('Nét $_step/$total', textAlign: TextAlign.center),),
              IconButton(
                tooltip: 'Nét tiếp',
                onPressed: _step < total && _selectedId == null
                    ? () => setState(() => _step++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        if (widget.hanVietLabel != null) ...[
          const SizedBox(height: 8),
          _HanVietLabel(widget.hanVietLabel!),
        ],
        if (widget.showComponents && orderedComponents.isNotEmpty) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KanjiSectionHeading('Thành phần'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in orderedComponents)
                      Semantics(
                        label: c.label,
                        selected: _selectedId == c.id,
                        child: SizedBox(
                          height: _componentChipHeight,
                          child: ChoiceChip(
                            showCheckmark: false,
                            key: ValueKey('component:${c.id}'),
                            selected: _selectedId == c.id,
                            label: c.form == null && _canHighlight(c)
                                ? _SupplementaryComponentLabel(
                                    document: widget.document,
                                    component: c,
                                    totalStrokes: total,
                                    ink: colors.onSurface,
                                    guide: colors.outlineVariant,
                                  )
                                : _ComponentLabel(c),
                            onSelected:
                                _canHighlight(c) ? (_) => _select(c) : null,
                          ),
                        ),
                      ),
                  ],
                ),
                if (orderedComponents.any((c) => !_canHighlight(c))) ...[
                  const Text(
                    'Dữ liệu thành phần và nét chưa khớp. Chưa thể tô nét.',
                  ),
                  TextButton(
                    onPressed: widget.onRetry,
                    child: const Text('Tải lại nét'),
                  ),
                ],
                if (_selectedId != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedId = null),
                    child: const Text('Bỏ chọn'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HanVietLabel extends StatelessWidget {
  const _HanVietLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      );
}

class _ComponentLabel extends StatelessWidget {
  const _ComponentLabel(this.component);
  final KanjiComponentOccurrence component;
  @override
  Widget build(BuildContext context) {
    final labelColor = Theme.of(context).colorScheme.onSurface;
    if (component.form == null) {
      return Text('Nét phụ', style: TextStyle(color: labelColor));
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: component.form,
            style: AppTypography.japanese(
              context,
              null,
              color: labelColor,
              fontSize: _radicalGlyphSize,
            ),
            locale: AppTypography.japaneseLocale,
          ),
          if (component.radical != null)
            TextSpan(text: ' ${component.radical!.nameVi}'),
        ],
      ),
      style: TextStyle(color: labelColor),
    );
  }
}

class _SupplementaryComponentLabel extends StatelessWidget {
  const _SupplementaryComponentLabel({
    required this.document,
    required this.component,
    required this.totalStrokes,
    required this.ink,
    required this.guide,
  });

  final StrokeDocument document;
  final KanjiComponentOccurrence component;
  final int totalStrokes;
  final Color ink;
  final Color guide;

  @override
  Widget build(BuildContext context) {
    final previewImage = SizedBox.square(
      dimension: _supplementaryStrokePreviewSize,
      child: document.supportsAnimation
          ? CustomPaint(
              painter: KanjiStrokePainter(
                document,
                totalStrokes.toDouble(),
                ink,
                guide,
                onlyStrokeIds: component.strokeIds.toSet(),
                drawGrid: false,
                strokeWidth: _supplementaryStrokeWidth,
                fitToStrokeBounds: true,
                maxScale: _supplementaryStrokeReferenceSize /
                    math.max(document.viewBox.width, document.viewBox.height),
              ),
            )
          : SvgPicture.string(
              document.staticSvgAt(
                0,
                ink: ink,
                onlyStrokeIds: component.strokeIds.toSet(),
                strokeWidth: _supplementaryStrokeWidth,
              ),
            ),
    );
    // Chỉ chiếm chiều cao dòng của nhãn bộ thủ. Hình nét vẫn vẽ ở 28 px,
    // nằm giữa chip mà không làm ô cao hơn.
    final preview = SizedBox(
      width: _supplementaryStrokePreviewSize,
      height: _radicalGlyphSize,
      child: OverflowBox(
        minWidth: _supplementaryStrokePreviewSize,
        maxWidth: _supplementaryStrokePreviewSize,
        minHeight: _supplementaryStrokePreviewSize,
        maxHeight: _supplementaryStrokePreviewSize,
        alignment: Alignment.center,
        child: previewImage,
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        preview,
        const SizedBox(width: 6),
        Text(
          'Nét phụ',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ],
    );
  }
}

class KanjiStrokePainter extends CustomPainter {
  KanjiStrokePainter(
    this.document,
    this.progress,
    this.ink,
    this.guide, {
    this.highlightedStrokeIds = const {},
    this.highlightColor = const Color(0xFFD32F2F),
    this.onlyStrokeIds,
    this.drawGrid = true,
    this.strokeWidth = 3,
    this.fitToStrokeBounds = false,
    this.maxScale,
  });
  final StrokeDocument document;
  final double progress;
  final Color ink, guide;
  final Set<String> highlightedStrokeIds;
  final Set<String>? onlyStrokeIds;
  final Color highlightColor;
  final bool drawGrid;
  final double strokeWidth;
  final bool fitToStrokeBounds;
  final double? maxScale;

  Rect _paintBounds() {
    Rect? bounds;
    for (var i = 0; i < document.paths.length; i++) {
      if (onlyStrokeIds != null &&
          !onlyStrokeIds!.contains(document.strokeIds[i])) {
        continue;
      }
      final pathBounds = document.paths[i].getBounds().inflate(strokeWidth);
      bounds = bounds == null ? pathBounds : bounds.expandToInclude(pathBounds);
    }
    return bounds ?? document.viewBox;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = guide
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    if (drawGrid) {
      canvas.drawRect(Offset.zero & size, grid);
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        grid,
      );
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        grid,
      );
    }
    final box = fitToStrokeBounds ? _paintBounds() : document.viewBox;
    final fittedScale =
        math.min(size.width / box.width, size.height / box.height);
    final scale =
        maxScale == null ? fittedScale : math.min(fittedScale, maxScale!);
    canvas.save();
    canvas.translate(
      (size.width - box.width * scale) / 2,
      (size.height - box.height * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(-box.left, -box.top);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < document.paths.length; i++) {
      final path = document.paths[i];
      final id = document.strokeIds[i];
      if (onlyStrokeIds != null && !onlyStrokeIds!.contains(id)) continue;
      canvas.drawPath(path, pen..color = guide.withValues(alpha: .35));
      final fraction = (progress - i).clamp(0.0, 1.0);
      pen.color = highlightedStrokeIds.contains(id) ? highlightColor : ink;
      if (fraction >= 1) {
        canvas.drawPath(path, pen);
      } else if (fraction > 0) {
        final metrics = path.computeMetrics().toList();
        var remaining =
            metrics.fold<double>(0, (sum, m) => sum + m.length) * fraction;
        for (final metric in metrics) {
          if (remaining <= 0) break;
          canvas.drawPath(
            metric.extractPath(0, math.min(remaining, metric.length)),
            pen,
          );
          remaining -= metric.length;
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(KanjiStrokePainter oldDelegate) =>
      oldDelegate.document != document ||
      oldDelegate.progress != progress ||
      oldDelegate.ink != ink ||
      oldDelegate.guide != guide ||
      oldDelegate.highlightedStrokeIds != highlightedStrokeIds ||
      oldDelegate.highlightColor != highlightColor ||
      oldDelegate.onlyStrokeIds != onlyStrokeIds ||
      oldDelegate.drawGrid != drawGrid ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.fitToStrokeBounds != fitToStrokeBounds ||
      oldDelegate.maxScale != maxScale;
}
