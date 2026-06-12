import 'package:flutter/material.dart';

abstract final class SrsConstants {
  static const double secondsPerDay = 86400;

  // Default interval cho từng level. Settings có thể override các giá trị này.
  static const Map<int, double> baseIntervals = {
    1: 2 / 24,
    2: 1.0,
    3: 2.0,
    4: 3.0,
    5: 5.0,
    6: 8.0,
  };

  static const int unlearnedLevel = 0;
  static const int minLevel = 1;
  static const int maxLevel = 6;

  static double defaultIntervalForLevel(int level) {
    if (level == unlearnedLevel) {
      return 0;
    }
    return baseIntervals[level] ?? baseIntervals[minLevel]!;
  }

  static const Map<int, String> levelNames = {
    0: 'Lv 0 - Chưa học',
    1: 'Lv 1 - Mới học',
    2: 'Lv 2 - Đang nhớ',
    3: 'Lv 3 - Khá quen',
    4: 'Lv 4 - Gần thuộc',
    5: 'Lv 5 - Rất nhớ',
    6: 'Lv 6 - Nhớ sâu',
  };

  static const Map<int, Color> levelColors = {
    0: Color(0xFFE5E7EB),
    1: Color(0xFFFEE2E2),
    2: Color(0xFFFFEDD5),
    3: Color(0xFFFFEDD5),
    4: Color(0xFFDCFCE7),
    5: Color(0xFFCCFBF1),
    6: Color(0xFFDBEAFE),
  };

  static const Map<int, Color> levelTextColors = {
    0: Color(0xFF374151),
    1: Color(0xFFB91C1C),
    2: Color(0xFFC2410C),
    3: Color(0xFFC2410C),
    4: Color(0xFF15803D),
    5: Color(0xFF0F766E),
    6: Color(0xFF1D4ED8),
  };
}
