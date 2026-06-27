import 'package:flutter/material.dart';

import '../../../../core/pitch_accent/pitch_accent_utils.dart';

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

    if (overlayAccent) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 4,
        children: [
          for (var i = 0; i < units.length; i++)
            _InlinePitchMora(
              text: units[i],
              isHigh: normalized[i] == 'H',
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: textColor ?? colors.onSurface,
              accentColor: accentColor ?? textColor ?? colors.onSurface,
            ),
          if (showPattern) ...[
            const SizedBox(width: 6),
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

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 0,
      runSpacing: 4,
      children: [
        for (var i = 0; i < units.length; i++)
          _PitchMora(
            text: units[i],
            isHigh: normalized[i] == 'H',
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor ?? colors.onSurface,
            accentColor: accentColor ?? textColor ?? colors.onSurface,
          ),
        if (showPattern) ...[
          const SizedBox(width: 6),
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

class _InlinePitchMora extends StatelessWidget {
  const _InlinePitchMora({
    required this.text,
    required this.isHigh,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    required this.accentColor,
  });

  final String text;
  final bool isHigh;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final width = _moraWidth(text, fontSize);

    return SizedBox(
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: -5,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: 3,
              decoration: BoxDecoration(
                color: isHigh ? accentColor : Colors.transparent,
              ),
            ),
          ),
          Text(
            text,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: fontWeight,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchMora extends StatelessWidget {
  const _PitchMora({
    required this.text,
    required this.isHigh,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    required this.accentColor,
  });

  final String text;
  final bool isHigh;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final width = _moraWidth(text, fontSize);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: width,
          height: 3,
          decoration: BoxDecoration(
            color: isHigh ? accentColor : Colors.transparent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

double _moraWidth(String text, double fontSize) {
  final visualUnits = text.characters.fold<double>(
    0,
    (total, char) => total + (_isSmallKana(char) ? 0.55 : 1),
  );

  return (fontSize * visualUnits * 1.08).clamp(16, 40).toDouble();
}

bool _isSmallKana(String char) {
  return const {
    'ぁ',
    'ぃ',
    'ぅ',
    'ぇ',
    'ぉ',
    'ゃ',
    'ゅ',
    'ょ',
    'ゎ',
    'ァ',
    'ィ',
    'ゥ',
    'ェ',
    'ォ',
    'ャ',
    'ュ',
    'ョ',
    'ヮ',
  }.contains(char);
}
