import 'package:flutter/material.dart';

import '../theme/app_typography.dart';
import '../utils/quiz_utils.dart';

class JapaneseQuizText extends StatelessWidget {
  const JapaneseQuizText({
    required this.text,
    this.primaryStyle,
    this.secondaryStyle,
    this.textAlign,
    super.key,
  });

  final QuizJapaneseText text;
  final TextStyle? primaryStyle;
  final TextStyle? secondaryStyle;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final basePrimary = primaryStyle ??
        Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 36,
              height: 1.18,
            );
    final baseSecondary = secondaryStyle ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.2,
            );

    if (!text.hasSecondary) {
      return Text(
        text.primary,
        locale: AppTypography.japaneseLocale,
        textAlign: textAlign,
        style: AppTypography.japanese(basePrimary),
      );
    }

    return Column(
      crossAxisAlignment: _crossAxisAlignmentFor(textAlign),
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text.primary,
          locale: AppTypography.japaneseLocale,
          textAlign: textAlign,
          style: AppTypography.japanese(basePrimary),
        ),
        const SizedBox(height: 4),
        Text(
          text.secondary!.trim(),
          locale: AppTypography.japaneseLocale,
          textAlign: textAlign,
          style: AppTypography.japanese(baseSecondary),
        ),
      ],
    );
  }

  CrossAxisAlignment _crossAxisAlignmentFor(TextAlign? align) {
    return switch (align) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.start,
    };
  }
}
