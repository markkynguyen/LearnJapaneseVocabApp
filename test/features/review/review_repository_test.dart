import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/review/domain/review_models.dart';
import 'package:jvocab/features/review/domain/review_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('due word with one wrong answer is rescheduled at the same level',
      () async {
    final store = _FakeReviewStore(
      settings: const AppSettings(srsLevel3IntervalDays: 4),
    );
    final repository = ReviewRepository(store: store);
    final session = _session(
      _result(
        _item(level: 3, intervalDays: 2, nextReviewAt: 1),
        wasDueAtStart: true,
        correctAnswers: 3,
        wrongAnswers: 1,
      ),
    );
    final before = _nowSeconds();

    final summary = await repository.applyEndSessionSrs(session);

    final after = _nowSeconds();
    final update = store.singleUpdate;
    expect(update.level, 3);
    expect(update.intervalDays, 4);
    expect(update.correctCount, 3);
    expect(update.wrongCount, 1);
    expectReviewTime(update.nextReviewAt, before, after, intervalDays: 4);
    expect(summary.words.single.newLevel, 3);
    expect(summary.words.single.message, 'Đã ôn Lv 3');
  });

  test('due word with two wrong answers is rescheduled at the same level',
      () async {
    final store = _FakeReviewStore(
      settings: const AppSettings(srsLevel2IntervalDays: 3),
    );
    final repository = ReviewRepository(store: store);
    final session = _session(
      _result(
        _item(level: 2, intervalDays: 1, nextReviewAt: 1),
        wasDueAtStart: true,
        correctAnswers: 2,
        wrongAnswers: 2,
      ),
    );
    final before = _nowSeconds();

    await repository.applyEndSessionSrs(session);

    final after = _nowSeconds();
    final update = store.singleUpdate;
    expect(update.level, 2);
    expect(update.intervalDays, 3);
    expectReviewTime(update.nextReviewAt, before, after, intervalDays: 3);
  });

  test('non-due fallback word with light wrong answers keeps its schedule',
      () async {
    final store = _FakeReviewStore(
      settings: const AppSettings(srsLevel4IntervalDays: 6),
    );
    final repository = ReviewRepository(store: store);
    final session = _session(
      _result(
        _item(level: 4, intervalDays: 3, nextReviewAt: 9999999999),
        wasDueAtStart: false,
        correctAnswers: 2,
        wrongAnswers: 1,
      ),
    );

    final summary = await repository.applyEndSessionSrs(session);

    final update = store.singleUpdate;
    expect(update.level, 4);
    expect(update.intervalDays, 3);
    expect(update.nextReviewAt, 9999999999);
    expect(summary.words.single.newLevel, isNull);
    expect(summary.words.single.nextReviewAt, isNull);
  });

  test('three wrong answers still use the selected srs decision', () async {
    final store = _FakeReviewStore(
      settings: const AppSettings(srsLevel2IntervalDays: 3),
    );
    final repository = ReviewRepository(store: store);
    final session = _session(
      _result(
        _item(level: 3, intervalDays: 2, nextReviewAt: 1),
        wasDueAtStart: true,
        wrongAnswers: 3,
        srsDecision: ReviewSrsDecision.minusOne,
      ),
    );
    final before = _nowSeconds();

    await repository.applyEndSessionSrs(session);

    final after = _nowSeconds();
    final update = store.singleUpdate;
    expect(update.level, 2);
    expect(update.intervalDays, 3);
    expectReviewTime(update.nextReviewAt, before, after, intervalDays: 3);
  });
}

void expectReviewTime(
  int actual,
  int before,
  int after, {
  required int intervalDays,
}) {
  expect(
    actual,
    inInclusiveRange(
      before + intervalDays * 86400,
      after + intervalDays * 86400 + 1,
    ),
  );
}

class _FakeReviewStore extends CloudStore {
  _FakeReviewStore({required this.settings})
      : super(
          SupabaseClient(
            'https://example.supabase.co',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  final AppSettings settings;
  List<SrsProgressEntry> updates = const [];

  SrsProgressEntry get singleUpdate {
    expect(updates, hasLength(1));
    return updates.single;
  }

  @override
  Future<AppSettings> getLearningSettings() async => settings;

  @override
  Future<void> applySrsUpdates(List<SrsProgressEntry> updates) async {
    this.updates = List.of(updates);
  }
}

ReviewSessionState _session(ReviewWordResult result) {
  return ReviewSessionState(
    questions: const [],
    currentIndex: 0,
    resultsByVocabId: {result.item.vocab.id: result},
    sessionStartTime: 0,
    retryLimit: 2,
    isFinished: true,
  );
}

ReviewWordResult _result(
  VocabWithProgress item, {
  required bool wasDueAtStart,
  int correctAnswers = 0,
  int wrongAnswers = 0,
  ReviewSrsDecision? srsDecision,
}) {
  return ReviewWordResult(
    item: item,
    wasDueAtStart: wasDueAtStart,
    correctAnswers: correctAnswers,
    wrongAnswers: wrongAnswers,
    srsDecision: srsDecision,
  );
}

VocabWithProgress _item({
  required int level,
  required double intervalDays,
  required int nextReviewAt,
}) {
  return VocabWithProgress(
    vocab: const VocabularyEntry(
      id: 'vocab-1',
      folderId: 'folder-1',
      kanji: '食べる',
      kana: 'たべる',
      romaji: 'taberu',
      meaning: 'ăn',
      isFavorite: false,
      createdAt: 0,
    ),
    progress: SrsProgressEntry(
      vocabId: 'vocab-1',
      level: level,
      intervalDays: intervalDays,
      nextReviewAt: nextReviewAt,
      correctCount: 0,
      wrongCount: 0,
    ),
  );
}

int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
