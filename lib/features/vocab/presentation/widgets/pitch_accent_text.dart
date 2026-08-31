import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/pitch_accent/pitch_accent_utils.dart';

const _pitchAccentLineHeight = 1.5;
const _pitchAccentLineOpacity = 0.5;
const _pitchAccentLineOffset = -3.0;

class PitchAccentText extends StatelessWidget {
  const PitchAccentText({
    required this.kana,
    required this.pattern,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w800,
    this.textColor,
    this.accentColor,
    this.showPattern = false,
    this.overlayAccent = false,
    super.key,
  });

  final String kana;
  final String? pattern;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? textColor;
  final Color? accentColor;
  final bool showPattern;
  final bool overlayAccent;

  @override
  Widget build(BuildContext context) {
    final normalized = normalizePitchPattern(pattern, kana);
    if (normalized == null) {
      return Text(
        kana,
        style: TextStyle(
          color: textColor ?? Theme.of(context).colorScheme.onSurface,
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: 1.1,
        ),
      );
    }

    final colors = Theme.of(context).colorScheme;
    final units = splitKanaMora(kana);
    final effectiveTextColor = textColor ?? colors.onSurface;
    final effectiveAccentColor = _mutedPitchAccentColor(
      accentColor ?? textColor ?? colors.onSurface,
    );

    final reading = _PitchAccentLayout(
      units: units,
      pattern: normalized,
      fontSize: fontSize,
      fontWeight: fontWeight,
      textColor: effectiveTextColor,
      accentColor: effectiveAccentColor,
      overlayAccent: overlayAccent,
    );

    if (!showPattern) {
      return reading;
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        reading,
        if (showPattern) ...[
          Text(
            normalized,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ],
    );
  }
}

class PitchAccentReading extends StatelessWidget {
  const PitchAccentReading({
    required this.kana,
    required this.pattern,
    this.romaji,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w800,
    this.textColor,
    this.accentColor,
    this.overlayAccent = true,
    super.key,
  });

  final String kana;
  final String? pattern;
  final String? romaji;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? textColor;
  final Color? accentColor;
  final bool overlayAccent;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        textColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final normalizedRomaji = romaji?.trim();

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      runSpacing: 5,
      children: [
        PitchAccentText(
          kana: kana,
          pattern: pattern,
          fontSize: fontSize,
          fontWeight: fontWeight,
          textColor: effectiveColor,
          accentColor: accentColor ?? effectiveColor,
          overlayAccent: overlayAccent,
        ),
        if (normalizedRomaji?.isNotEmpty == true)
          Text(
            '• $normalizedRomaji',
            style: TextStyle(
              color: effectiveColor,
              fontSize: fontSize * 0.82,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
      ],
    );
  }
}

class _PitchAccentLayout extends StatelessWidget {
  const _PitchAccentLayout({
    required this.units,
    required this.pattern,
    required this.fontSize,
    required this.fontWeight,
    required this.textColor,
    required this.accentColor,
    required this.overlayAccent,
  });

  final List<String> units;
  final String pattern;
  final double fontSize;
  final FontWeight fontWeight;
  final Color textColor;
  final Color accentColor;
  final bool overlayAccent;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: overlayAccent ? 1.2 : 1.1,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final measured = [
          for (var i = 0; i < units.length; i++)
            _MeasuredMora(
              text: units[i],
              isHigh: pattern[i] == 'H',
              width: _measureMoraWidth(context, units[i], textStyle),
            ),
        ];
        final rows = _buildPitchRows(measured, constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              _PitchAccentRow(
                row: rows[i],
                textStyle: textStyle,
                accentColor: accentColor,
                overlayAccent: overlayAccent,
              ),
              if (i < rows.length - 1) const SizedBox(height: 4),
            ],
          ],
        );
      },
    );
  }
}

class _PitchAccentRow extends StatelessWidget {
  const _PitchAccentRow({
    required this.row,
    required this.textStyle,
    required this.accentColor,
    required this.overlayAccent,
  });

  final _PitchAccentRowData row;
  final TextStyle textStyle;
  final Color accentColor;
  final bool overlayAccent;

  @override
  Widget build(BuildContext context) {
    final textRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in row.items)
          SizedBox(
            width: item.width,
            child: Text(
              item.text,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
      ],
    );

    if (overlayAccent) {
      return SizedBox(
        width: row.width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final segment in row.segments)
              Positioned(
                top: _pitchAccentLineOffset,
                left: segment.left,
                width: segment.width,
                child: _PitchAccentLine(color: accentColor),
              ),
            textRow,
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: row.width,
          height: _pitchAccentLineHeight,
          child: Stack(
            children: [
              for (final segment in row.segments)
                Positioned(
                  top: 0,
                  left: segment.left,
                  width: segment.width,
                  child: _PitchAccentLine(color: accentColor),
                ),
            ],
          ),
        ),
        const SizedBox(height: 1),
        textRow,
      ],
    );
  }
}

class _PitchAccentLine extends StatelessWidget {
  const _PitchAccentLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      height: _pitchAccentLineHeight,
      decoration: BoxDecoration(color: color),
    );
  }
}

class _MeasuredMora {
  const _MeasuredMora({
    required this.text,
    required this.isHigh,
    required this.width,
  });

  final String text;
  final bool isHigh;
  final double width;
}

class _PitchAccentRowData {
  const _PitchAccentRowData({
    required this.items,
    required this.width,
    required this.segments,
  });

  final List<_MeasuredMora> items;
  final double width;
  final List<_PitchAccentSegment> segments;
}

class _PitchAccentSegment {
  const _PitchAccentSegment({
    required this.left,
    required this.width,
  });

  final double left;
  final double width;
}

List<_PitchAccentRowData> _buildPitchRows(
  List<_MeasuredMora> items,
  double maxWidth,
) {
  if (items.isEmpty) {
    return const [];
  }

  final effectiveMaxWidth =
      maxWidth.isFinite ? math.max(maxWidth, 0) : maxWidth;
  final rows = <_PitchAccentRowData>[];
  var current = <_MeasuredMora>[];
  var currentWidth = 0.0;

  void finishRow() {
    if (current.isEmpty) {
      return;
    }
    rows.add(
      _PitchAccentRowData(
        items: List.unmodifiable(current),
        width: currentWidth,
        segments: _buildPitchSegments(current),
      ),
    );
    current = <_MeasuredMora>[];
    currentWidth = 0;
  }

  for (final item in items) {
    final wouldOverflow = current.isNotEmpty &&
        effectiveMaxWidth.isFinite &&
        currentWidth + item.width > effectiveMaxWidth;
    if (wouldOverflow) {
      finishRow();
    }
    current.add(item);
    currentWidth += item.width;
  }
  finishRow();

  return rows;
}

List<_PitchAccentSegment> _buildPitchSegments(List<_MeasuredMora> items) {
  final segments = <_PitchAccentSegment>[];
  var offset = 0.0;
  double? start;

  for (final item in items) {
    if (item.isHigh) {
      start ??= offset;
    } else if (start != null) {
      segments.add(
        _PitchAccentSegment(
          left: start,
          width: offset - start,
        ),
      );
      start = null;
    }
    offset += item.width;
  }

  if (start != null) {
    segments.add(
      _PitchAccentSegment(
        left: start,
        width: offset - start,
      ),
    );
  }

  return segments;
}

double _measureMoraWidth(
  BuildContext context,
  String text,
  TextStyle style,
) {
  final fontSize = style.fontSize ?? 18;
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    maxLines: 1,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();

  return math.max(
    painter.width + fontSize * 0.08,
    fontSize * 0.8,
  );
}

Color _mutedPitchAccentColor(Color color) =>
    color.withValues(alpha: _pitchAccentLineOpacity);
