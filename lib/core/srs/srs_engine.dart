import 'dart:math';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/srs_constants.dart';
import '../database/app_database.dart';
import '../utils/time_utils.dart';

part 'srs_engine.g.dart';

typedef SrsIntervalResolver = double Function(int level);

class SrsResult {
  const SrsResult({
    required this.newLevel,
    required this.newIntervalDays,
    required this.newNextReviewAt,
    required this.message,
  });

  final int newLevel;
  final double newIntervalDays;
  final int newNextReviewAt;
  final String message;
}

class SrsEngine {
  const SrsEngine({
    SrsIntervalResolver? intervalForLevel,
    DateTime Function()? now,
  })  : _intervalForLevel =
            intervalForLevel ?? SrsConstants.defaultIntervalForLevel,
        _now = now ?? DateTime.now;

  final SrsIntervalResolver _intervalForLevel;
  final DateTime Function() _now;

  SrsResult processCorrect(SrsProgressEntry current) {
    final newLevel = current.level < SrsConstants.minLevel
        ? SrsConstants.minLevel
        : current.level < SrsConstants.maxLevel
            ? current.level + 1
            : SrsConstants.maxLevel;
    final newIntervalDays = current.level < SrsConstants.maxLevel
        ? _intervalForLevel(newLevel)
        : current.intervalDays + 1.0;

    return SrsResult(
      newLevel: newLevel,
      newIntervalDays: newIntervalDays,
      newNextReviewAt: calculateNextReview(newIntervalDays),
      message: newLevel == SrsConstants.maxLevel &&
              current.level == SrsConstants.maxLevel
          ? 'Giữ Lv 6, tăng thêm 1 ngày'
          : 'Tăng lên Lv $newLevel',
    );
  }

  SrsResult processMinus1(SrsProgressEntry current) {
    return _minusOne(current, messagePrefix: 'Giảm xuống');
  }

  SrsResult processReset(SrsProgressEntry current) {
    return _reset(message: 'Reset về Lv 1');
  }

  SrsResult manualMinus1(SrsProgressEntry current) {
    return _minusOne(current, messagePrefix: 'Đã giảm xuống');
  }

  SrsResult manualReset(SrsProgressEntry current) {
    return _reset(message: 'Đã reset về Lv 1');
  }

  bool isDueAtSessionStart(
    SrsProgressEntry current, {
    required int sessionStartTime,
  }) {
    return current.nextReviewAt <= sessionStartTime;
  }

  SrsResult? processEndSessionSuccess(
    SrsProgressEntry current, {
    required bool isDue,
    required bool isMarkedForReview,
  }) {
    if (!isDue || isMarkedForReview) {
      return null;
    }

    return processCorrect(current);
  }

  int calculateNextReview(double intervalDays) {
    return (_now().millisecondsSinceEpoch / 1000).round() +
        (intervalDays * SrsConstants.secondsPerDay).round();
  }

  String formatTimeUntilReview(int nextReviewAt) {
    return formatNextReview(nextReviewAt);
  }

  SrsResult _minusOne(
    SrsProgressEntry current, {
    required String messagePrefix,
  }) {
    final newLevel = max(SrsConstants.minLevel, current.level - 1);
    final newIntervalDays = _intervalForLevel(newLevel);

    return SrsResult(
      newLevel: newLevel,
      newIntervalDays: newIntervalDays,
      newNextReviewAt: calculateNextReview(newIntervalDays),
      message: '$messagePrefix Lv $newLevel',
    );
  }

  SrsResult _reset({required String message}) {
    final newIntervalDays = _intervalForLevel(SrsConstants.minLevel);

    return SrsResult(
      newLevel: SrsConstants.minLevel,
      newIntervalDays: newIntervalDays,
      newNextReviewAt: calculateNextReview(newIntervalDays),
      message: message,
    );
  }
}

SrsIntervalResolver settingsIntervalResolver(AppSettings settings) {
  return (level) {
    switch (level) {
      case 1:
        return settings.srsLevel1IntervalDays;
      case 2:
        return settings.srsLevel2IntervalDays;
      case 3:
        return settings.srsLevel3IntervalDays;
      case 4:
        return settings.srsLevel4IntervalDays;
      case 5:
        return settings.srsLevel5IntervalDays;
      case 6:
        return settings.srsLevel6IntervalDays;
      default:
        return SrsConstants.defaultIntervalForLevel(level);
    }
  };
}

@Riverpod(keepAlive: true)
SrsEngine srsEngine(SrsEngineRef ref) {
  return const SrsEngine();
}
