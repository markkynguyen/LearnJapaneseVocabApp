import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/constants/srs_constants.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/core/srs/srs_engine.dart';

void main() {
  const fixedNow = 1700000000;
  late SrsEngine engine;

  setUp(() {
    engine = SrsEngine(
      now: () => DateTime.fromMillisecondsSinceEpoch(fixedNow * 1000),
    );
  });

  test('correct lv1 moves to lv2 with default 1 day interval', () {
    final result = engine.processCorrect(_progress(level: 1));

    expect(result.newLevel, 2);
    expect(result.newIntervalDays, 1.0);
    expect(result.newNextReviewAt, fixedNow + 86400);
  });

  test('correct lv0 moves to lv1 with default 2 hour interval', () {
    final result = engine.processCorrect(_progress(level: 0));

    expect(result.newLevel, 1);
    expect(result.newIntervalDays, SrsConstants.defaultIntervalForLevel(1));
    expect(result.newNextReviewAt, fixedNow + 2 * 3600);
  });

  test('correct lv5 moves to lv6 with default 8 day interval', () {
    final result = engine.processCorrect(_progress(level: 5));

    expect(result.newLevel, 6);
    expect(result.newIntervalDays, 8.0);
    expect(result.newNextReviewAt, fixedNow + 8 * 86400);
  });

  test('correct lv6 keeps lv6 and increases interval by 1 day', () {
    final result = engine.processCorrect(
      _progress(level: 6, intervalDays: 8.0),
    );

    expect(result.newLevel, 6);
    expect(result.newIntervalDays, 9.0);
    expect(result.newNextReviewAt, fixedNow + 9 * 86400);
  });

  test('minus1 lv3 moves to lv2 with default 1 day interval', () {
    final result = engine.processMinus1(_progress(level: 3));

    expect(result.newLevel, 2);
    expect(result.newIntervalDays, 1.0);
  });

  test('minus1 lv1 stays at lv1 with 2 hour interval', () {
    final result = engine.processMinus1(_progress(level: 1));

    expect(result.newLevel, 1);
    expect(result.newIntervalDays, SrsConstants.defaultIntervalForLevel(1));
    expect(result.newNextReviewAt, fixedNow + 2 * 3600);
  });

  test('minus1 lv0 moves into lv1 and never returns lv0', () {
    final result = engine.processMinus1(_progress(level: 0));

    expect(result.newLevel, 1);
    expect(result.newIntervalDays, SrsConstants.defaultIntervalForLevel(1));
  });

  test('reset lv5 moves to lv1 with 2 hour interval', () {
    final result = engine.processReset(_progress(level: 5));

    expect(result.newLevel, 1);
    expect(result.newIntervalDays, SrsConstants.defaultIntervalForLevel(1));
    expect(result.newNextReviewAt, fixedNow + 2 * 3600);
  });

  test('custom interval resolver overrides default intervals', () {
    final customEngine = SrsEngine(
      intervalForLevel: (level) => level * 10.0,
      now: () => DateTime.fromMillisecondsSinceEpoch(fixedNow * 1000),
    );

    final result = customEngine.processCorrect(_progress(level: 2));

    expect(result.newLevel, 3);
    expect(result.newIntervalDays, 30.0);
  });

  test('non-due successful word does not change at end of session', () {
    final result = engine.processEndSessionSuccess(
      _progress(level: 2),
      isDue: false,
      isMarkedForReview: false,
    );

    expect(result, isNull);
  });

  test('due successful word levels up at end of session', () {
    final result = engine.processEndSessionSuccess(
      _progress(level: 2),
      isDue: true,
      isMarkedForReview: false,
    );

    expect(result, isNotNull);
    expect(result!.newLevel, 3);
    expect(result.newIntervalDays, 2.0);
  });

  test('marked word does not level up automatically', () {
    final result = engine.processEndSessionSuccess(
      _progress(level: 2),
      isDue: true,
      isMarkedForReview: true,
    );

    expect(result, isNull);
  });

  test('isDueAtSessionStart uses fixed session start time', () {
    expect(
      engine.isDueAtSessionStart(
        _progress(level: 1, nextReviewAt: 99),
        sessionStartTime: 100,
      ),
      isTrue,
    );
    expect(
      engine.isDueAtSessionStart(
        _progress(level: 1, nextReviewAt: 101),
        sessionStartTime: 100,
      ),
      isFalse,
    );
  });
}

SrsProgressEntry _progress({
  required int level,
  double? intervalDays,
  int nextReviewAt = 0,
}) {
  return SrsProgressEntry(
    vocabId: 'vocab-1',
    level: level,
    intervalDays: intervalDays ?? SrsConstants.defaultIntervalForLevel(level),
    nextReviewAt: nextReviewAt,
    correctCount: 0,
    wrongCount: 0,
  );
}
