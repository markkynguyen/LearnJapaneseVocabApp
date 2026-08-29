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

  test('global review session only loads active folders', () async {
    final active = _item(
      vocabId: 'active-vocab',
      folderId: 'active-folder',
      level: 1,
      intervalDays: 1,
      nextReviewAt: 1,
    );
    final paused = _item(
      vocabId: 'paused-vocab',
      folderId: 'paused-folder',
      level: 1,
      intervalDays: 1,
      nextReviewAt: 1,
    );
    final store = _FakeReviewStore(
      settings: const AppSettings(sessionSize: 10),
      activeVocab: [active],
      allVocab: [active, paused],
    );
    final repository = ReviewRepository(store: store);

    final session = await repository.createSession();

    expect(store.lastGetAllVocabActiveOnly, isTrue);
    expect(session.resultsByVocabId.keys, ['active-vocab']);
  });

  test('folder review session still loads a paused folder directly', () async {
    final paused = _item(
      vocabId: 'paused-vocab',
      folderId: 'paused-folder',
      level: 1,
      intervalDays: 1,
      nextReviewAt: 1,
    );
    final store = _FakeReviewStore(
      settings: const AppSettings(sessionSize: 10),
      folderVocab: {
        'paused-folder': [paused],
      },
    );
    final repository = ReviewRepository(store: store);

    final session = await repository.createSession(folderId: 'paused-folder');

    expect(store.lastFolderId, 'paused-folder');
    expect(session.resultsByVocabId.keys, ['paused-vocab']);
  });

  test('review session puts write questions before other question types',
      () async {
    const writeCount = 2;
    final words = [
      _item(
        vocabId: 'vocab-1',
        level: 1,
        intervalDays: 1,
        nextReviewAt: 1,
      ),
      _item(
        vocabId: 'vocab-2',
        level: 1,
        intervalDays: 1,
        nextReviewAt: 1,
      ),
      _item(
        vocabId: 'vocab-3',
        level: 1,
        intervalDays: 1,
        nextReviewAt: 1,
      ),
    ];
    final store = _FakeReviewStore(
      settings: const AppSettings(
        quizListenCount: 1,
        quizWriteCount: writeCount,
        quizChooseWordCount: 1,
        quizChooseMeaningCount: 1,
      ),
    );
    final repository = ReviewRepository(store: store);

    final session = await repository.createSessionFromWords(words);

    final types = session.questions.map((question) => question.type).toList();
    final expectedWriteQuestions = words.length * writeCount;
    expect(types, hasLength(words.length * 5));
    expect(
      types.take(expectedWriteQuestions),
      everyElement(ReviewQuestionType.write),
    );
    expect(
      types.skip(expectedWriteQuestions),
      isNot(contains(ReviewQuestionType.write)),
    );
    expect(
      types.where((type) => type == ReviewQuestionType.listen),
      hasLength(words.length),
    );
    expect(
      types.where((type) => type == ReviewQuestionType.write),
      hasLength(expectedWriteQuestions),
    );
    expect(
      types.where((type) => type == ReviewQuestionType.chooseWord),
      hasLength(words.length),
    );
    expect(
      types.where((type) => type == ReviewQuestionType.chooseMeaning),
      hasLength(words.length),
    );
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
  _FakeReviewStore({
    required this.settings,
    this.activeVocab = const [],
    this.allVocab = const [],
    this.folderVocab = const {},
  }) : super(
          SupabaseClient(
            'https://example.supabase.co',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  final AppSettings settings;
  final List<VocabWithProgress> activeVocab;
  final List<VocabWithProgress> allVocab;
  final Map<String, List<VocabWithProgress>> folderVocab;
  List<SrsProgressEntry> updates = const [];
  bool? lastGetAllVocabActiveOnly;
  String? lastFolderId;

  SrsProgressEntry get singleUpdate {
    expect(updates, hasLength(1));
    return updates.single;
  }

  @override
  Future<AppSettings> getLearningSettings() async => settings;

  @override
  Future<List<VocabWithProgress>> getAllVocab({
    bool activeOnly = true,
  }) async {
    lastGetAllVocabActiveOnly = activeOnly;
    return activeOnly ? activeVocab : allVocab;
  }

  @override
  Future<List<VocabWithProgress>> getVocabByFolder(
    String folderId, {
    VocabSortMode sortMode = VocabSortMode.newest,
    String searchQuery = '',
    bool favoritesOnly = false,
  }) async {
    lastFolderId = folderId;
    return folderVocab[folderId] ?? const [];
  }

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
  String vocabId = 'vocab-1',
  String folderId = 'folder-1',
  required int level,
  required double intervalDays,
  required int nextReviewAt,
}) {
  return VocabWithProgress(
    vocab: VocabularyEntry(
      id: vocabId,
      folderId: folderId,
      kanji: '食べる',
      kana: 'たべる',
      romaji: 'taberu',
      meaning: 'ăn',
      isFavorite: false,
      createdAt: 0,
    ),
    progress: SrsProgressEntry(
      vocabId: vocabId,
      level: level,
      intervalDays: intervalDays,
      nextReviewAt: nextReviewAt,
      correctCount: 0,
      wrongCount: 0,
    ),
  );
}

int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
