import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData light() {
    return _buildTheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      background: AppColors.background,
      surface: AppColors.surface,
      border: AppColors.border,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.danger,
    );
  }

  static ThemeData dark() {
    return _buildTheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      background: AppColors.backgroundDark,
      surface: AppColors.surfaceDark,
      border: AppColors.borderDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      error: AppColors.dangerDark,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color border,
    required Color onSurface,
    required Color onSurfaceVariant,
    required Color error,
  }) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      outline: border,
      error: error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamilyFallback: AppTypography.japaneseFontFamilyFallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: primary.withValues(alpha: 0.5), width: 1.33),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        labelStyle: TextStyle(
          color: onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: TextStyle(
          color: onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            color: isSelected ? onSurface : onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? const Color(0xFFF3F4F6)
            : const Color(0xFF1F2937),
        contentTextStyle: TextStyle(
          color: brightness == Brightness.dark
              ? const Color(0xFF111827)
              : Colors.white,
          fontWeight: FontWeight.w700,
        ),
        actionTextColor:
            brightness == Brightness.dark ? const Color(0xFF4338CA) : null,
        closeIconColor: brightness == Brightness.dark
            ? const Color(0xFF111827)
            : Colors.white,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: onSurfaceVariant,
        indicatorColor: primary,
      ),
    );
  }
}

extension AppThemeColors on BuildContext {
  Color get appSuccess {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColors.successDark
        : AppColors.success;
  }

  Color get appWarning {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColors.warningDark
        : AppColors.warning;
  }

  Color get appDanger {
    return Theme.of(this).colorScheme.error;
  }
}
