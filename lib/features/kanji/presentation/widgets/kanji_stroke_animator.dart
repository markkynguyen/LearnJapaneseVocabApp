import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/kanji_stroke_service.dart';

class KanjiStrokeViewer extends ConsumerWidget {
  const KanjiStrokeViewer({required this.character, super.key});
  final String character;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(kanjiStrokesProvider(character))
      .when(
        data: (document) =>
            KanjiStrokeAnimator(key: ValueKey(character), document: document),
        loading: () => const SizedBox(
          height: 220,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => Column(
          children: [
            const Text(
              'Chưa tải được thứ tự nét. Bạn vẫn có thể đọc nghĩa và thành phần bên dưới.',
            ),
            TextButton.icon(
              onPressed: () => ref.invalidate(kanjiStrokesProvider(character)),
              icon: const Icon(Icons.refresh),
              label: const Text('Tải lại nét'),
            ),
          ],
        ),
      );
}

class KanjiStrokeAnimator extends StatefulWidget {
  const KanjiStrokeAnimator({required this.document, super.key});
  final StrokeDocument document;
  @override
  State<KanjiStrokeAnimator> createState() => _KanjiStrokeAnimatorState();
}

class _KanjiStrokeAnimatorState extends State<KanjiStrokeAnimator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animated = false;
  bool _reduceMotion = false;
  int _step = 1;
  @override
  void initState() {
    super.initState();
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
      _step = 1;
      _animated = false;
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
    final total = widget.document.strokeCount;
    final colors = Theme.of(context).colorScheme;
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
          onSelectionChanged:
              _reduceMotion || !widget.document.supportsAnimation
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
                  dimension: 200,
                  child: !widget.document.supportsAnimation
                      ? SvgPicture.string(
                          widget.document.staticSvgAt(_step),
                          colorFilter:
                              ColorFilter.mode(colors.primary, BlendMode.srcIn),
                          errorBuilder: (context, error, stack) => const Center(
                            child: Text(
                              'Dữ liệu nét bị lỗi. Nghĩa và cách đọc vẫn dùng được.',
                            ),
                          ),
                        )
                      : CustomPaint(
                          painter: _StrokePainter(
                            widget.document,
                            _animated
                                ? _controller.value * total
                                : _step.toDouble(),
                            colors.primary,
                            colors.outlineVariant,
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
                onPressed: _step > 0 ? () => setState(() => _step--) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text('Nét $_step/$total'),
              IconButton(
                tooltip: 'Nét tiếp',
                onPressed: _step < total ? () => setState(() => _step++) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
      ],
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.document, this.progress, this.ink, this.guide);
  final StrokeDocument document;
  final double progress;
  final Color ink, guide;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = guide
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
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
    final box = document.viewBox;
    final scale = math.min(size.width / box.width, size.height / box.height);
    canvas.save();
    canvas.translate(
      (size.width - box.width * scale) / 2,
      (size.height - box.height * scale) / 2,
    );
    canvas.scale(scale);
    canvas.translate(-box.left, -box.top);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < document.paths.length; i++) {
      final path = document.paths[i];
      canvas.drawPath(path, pen..color = guide.withValues(alpha: .35));
      final fraction = (progress - i).clamp(0.0, 1.0);
      pen.color = ink;
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
  bool shouldRepaint(_StrokePainter oldDelegate) =>
      oldDelegate.document != document ||
      oldDelegate.progress != progress ||
      oldDelegate.ink != ink ||
      oldDelegate.guide != guide;
}
