import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_models.dart';

@immutable
class JapaneseTypographyTheme extends ThemeExtension<JapaneseTypographyTheme> {
  const JapaneseTypographyTheme({
    required this.fontChoice,
  });

  final JapaneseFontChoice fontChoice;

  @override
  JapaneseTypographyTheme copyWith({JapaneseFontChoice? fontChoice}) =>
      JapaneseTypographyTheme(fontChoice: fontChoice ?? this.fontChoice);

  @override
  JapaneseTypographyTheme lerp(
    ThemeExtension<JapaneseTypographyTheme>? other,
    double t,
  ) =>
      t < 0.5 || other is! JapaneseTypographyTheme ? this : other;
}

abstract final class AppTypography {
  static const japaneseLocale = Locale('ja', 'JP');

  /// Primary font family used across the application (Noto Sans JP).
  static String? get defaultFontFamily => GoogleFonts.notoSansJp().fontFamily;

  /// Fallback chain prioritizing Japanese fonts across OSs (Windows, macOS, iOS, Android, Linux).
  static const japaneseFontFamilyFallback = <String>[
    'Noto Sans JP',
    'Noto Sans CJK JP',
    'Noto Sans CJK',
    'KleeOne',
    'BIZ UDPGothic',
    'Yu Gothic',
    'Meiryo',
    'Hiragino Sans',
    'Roboto',
    'sans-serif',
  ];

  static JapaneseFontChoice fontChoiceFor(BuildContext context) =>
      Theme.of(context).extension<JapaneseTypographyTheme>()?.fontChoice ??
      JapaneseFontChoice.textbook;

  /// Japanese text style, using the device's chosen font for both kana and kanji.
  static TextStyle japanese(
    BuildContext context,
    TextStyle? base, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) {
    return japaneseForChoice(
      fontChoiceFor(context),
      base,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }

  static TextStyle japaneseForChoice(
    JapaneseFontChoice choice,
    TextStyle? base, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) {
    return (base ?? const TextStyle()).copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      fontFamily: choice.fontFamily,
      fontFamilyFallback: japaneseFontFamilyFallback,
    );
  }

  /// Kept as a semantic helper for vocabulary displays; it uses the same
  /// selected typeface as kana so Japanese text stays visually consistent.
  static TextStyle kanji(
    BuildContext context,
    TextStyle? base, {
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) {
    return japanese(
      context,
      base,
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
    );
  }
}
