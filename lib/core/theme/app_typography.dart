import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const japaneseLocale = Locale('ja', 'JP');

  static const japaneseFontFamilyFallback = <String>[
    'Noto Sans JP',
    'Noto Sans CJK JP',
    'Noto Sans CJK',
    'Yu Gothic',
    'Meiryo',
    'Hiragino Sans',
    'Roboto',
    'sans-serif',
  ];

  static TextStyle japanese(
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
      fontFamilyFallback: japaneseFontFamilyFallback,
    );
  }
}
