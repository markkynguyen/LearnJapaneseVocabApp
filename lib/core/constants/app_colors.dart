import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF818CF8);
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF101114);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1A1C22);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF2F3340);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFFB8C0CC);
  static const Color success = Color(0xFF16A34A);
  static const Color successDark = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerDark = Color(0xFFF87171);

  static const List<Color> folderPresets = [
    primary,
    Color(0xFF14B8A6),
    Color(0xFFE11D48),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
  ];
}
