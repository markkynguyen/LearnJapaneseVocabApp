import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/audio/audio_service.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/core/router/app_router.dart';
import 'package:jvocab/core/router/app_routes.dart';
import 'package:jvocab/features/learning/domain/learning_models.dart';
import 'package:jvocab/features/learning/presentation/learning_preview_screen.dart';
import 'package:jvocab/features/learning/presentation/providers/learning_provider.dart';
import 'package:jvocab/features/review/domain/review_models.dart';
import 'package:jvocab/features/review/presentation/providers/review_session_provider.dart';
import 'package:jvocab/features/review/presentation/review_result_screen.dart';
import 'package:jvocab/features/review/presentation/review_session_screen.dart';
import 'package:jvocab/features/vocab/presentation/widgets/pitch_accent_text.dart';
import 'package:jvocab/features/vocab/presentation/widgets/vocabulary_study_card.dart';

void main() {
  test('review exit route follows the session source', () {
    expect(AppRoutes.reviewExit(null), AppRoutes.home);
    expect(
      AppRoutes.reviewExit('folder-7'),
      AppRoutes.folderVocab('folder-7'),
    );
  });

  testWidgets('new-word preview uses a readable flashcard layout on mobile',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final item = _item(
      level: 0,
      example: '毎日ご飯を食べる。',
      pitchAccent: 'HHL',
    );
    final session = LearningSessionState(
      folderId: 'folder-1',
      questions: const [],
      currentIndex: 0,
      resultsByVocabId: {
        item.vocab.id: LearningWordResult(
          item: item,
          totalRequirements: 1,
        ),
      },
      retryLimit: 2,
      quizScript: 'kanji',
    );
    final audio = _FakeAudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningControllerProvider.overrideWith(
            () => _FakeLearningController(session),
          ),
          audioServiceProvider.overrideWith((ref) => audio),
        ],
        child: const MaterialApp(
          home: LearningPreviewScreen(folderId: 'folder-1'),
        ),
      ),
    );
    await tester.pump();

    expect(audio.spokenVocabIds, ['vocab-1']);
    expect(find.text('Từ mới 1/1'), findsOneWidget);
    expect(find.text('Nghĩa'), findsOneWidget);
    expect(find.text('Động từ nhóm 2'), findsOneWidget);
    expect(find.text('毎日ご飯を食べる。'), findsOneWidget);
    expect(find.text('Bắt đầu quiz'), findsOneWidget);
    expect(find.byType(VocabularyStudyCard), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('new-word preview speaks again when the visible card changes',
      (tester) async {
    final first = _item(level: 0);
    final second = _item(id: 'vocab-2', level: 0, meaning: 'uống');
    final session = LearningSessionState(
      folderId: 'folder-1',
      questions: const [],
      currentIndex: 0,
      resultsByVocabId: {
        first.vocab.id: LearningWordResult(
          item: first,
          totalRequirements: 1,
        ),
        second.vocab.id: LearningWordResult(
          item: second,
          totalRequirements: 1,
        ),
      },
      retryLimit: 2,
      quizScript: 'kanji',
    );
    final audio = _FakeAudioService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningControllerProvider.overrideWith(
            () => _FakeLearningController(session),
          ),
          audioServiceProvider.overrideWith((ref) => audio),
        ],
        child: const MaterialApp(
          home: LearningPreviewScreen(folderId: 'folder-1'),
        ),
      ),
    );
    await tester.pump();
    expect(audio.spokenVocabIds, ['vocab-1']);

    await tester.tap(find.widgetWithText(FilledButton, 'Tiếp'));
    await tester.pumpAndSettle();
    expect(audio.spokenVocabIds, ['vocab-1', 'vocab-2']);
  });

  testWidgets(
      'learning quiz hides bottom navigation and shows choose-word note',
      (tester) async {
    final item = _item(level: 0);
    final question = LearningQuestion(
      item: item,
      type: LearningQuestionType.chooseWord,
      japaneseText: '食べる',
      choices: const ['食べる', '飲む', '行く', '寝る'],
      requirementId: 'choose-word-1',
    );
    final session = LearningSessionState(
      folderId: 'folder-1',
      questions: [question],
      currentIndex: 0,
      resultsByVocabId: {
        item.vocab.id: LearningWordResult(
          item: item,
          totalRequirements: 1,
        ),
      },
      retryLimit: 2,
      quizScript: 'kanji',
    );
    final container = ProviderContainer(
      overrides: [
        routerGuardEnabledProvider.overrideWithValue(false),
        learningControllerProvider.overrideWith(
          () => _FakeLearningController(session),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider)
      ..go(AppRoutes.learningSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Động từ nhóm 2'), findsOneWidget);
    expect(find.text('食べる'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('review quiz hides bottom navigation and shows choose-word note',
      (tester) async {
    final item = _item(level: 1, pitchAccent: 'HHL');
    final question = ReviewQuestion(
      item: item,
      type: ReviewQuestionType.chooseWord,
      japaneseText: 'たべる',
      choices: const ['たべる', 'のむ', 'いく', 'ねる'],
      retryCount: 0,
    );
    final session = ReviewSessionState(
      questions: [question],
      currentIndex: 0,
      resultsByVocabId: {
        item.vocab.id: ReviewWordResult(
          item: item,
          wasDueAtStart: true,
        ),
      },
      sessionStartTime: 0,
      retryLimit: 2,
      isFinished: false,
      folderId: 'folder-1',
    );
    final audio = _FakeAudioService();
    final container = ProviderContainer(
      overrides: [
        routerGuardEnabledProvider.overrideWithValue(false),
        reviewSessionControllerProvider.overrideWith(
          () => _FakeReviewController(session),
        ),
        audioServiceProvider.overrideWith((ref) => audio),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider)
      ..go(AppRoutes.reviewSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Động từ nhóm 2'), findsOneWidget);
    expect(find.text('たべる'), findsOneWidget);
    expect(find.byType(PitchAccentText), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, 'たべる'));
    await tester.pumpAndSettle();
    expect(find.byType(PitchAccentText), findsOneWidget);
    expect(find.text('たべる'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feedback audio finishes before the next listening prompt plays',
      (tester) async {
    final first = _item(level: 0, pitchAccent: 'HHL');
    final second = _item(id: 'vocab-2', level: 0, meaning: 'uống');
    final questions = [
      LearningQuestion(
        item: first,
        type: LearningQuestionType.chooseWord,
        japaneseText: '食べる',
        choices: const ['食べる', '飲む', '行く', '寝る'],
        requirementId: 'choose-word-1',
      ),
      LearningQuestion(
        item: second,
        type: LearningQuestionType.listen,
        japaneseText: '飲む',
        choices: const ['uống', 'ăn', 'đi', 'ngủ'],
        requirementId: 'listen-2',
      ),
    ];
    final session = LearningSessionState(
      folderId: 'folder-1',
      questions: questions,
      currentIndex: 0,
      resultsByVocabId: {
        first.vocab.id: LearningWordResult(
          item: first,
          totalRequirements: 1,
        ),
        second.vocab.id: LearningWordResult(
          item: second,
          totalRequirements: 1,
        ),
      },
      retryLimit: 2,
      quizScript: 'kanji',
    );
    final audio = _FakeAudioService();
    final container = ProviderContainer(
      overrides: [
        routerGuardEnabledProvider.overrideWithValue(false),
        learningControllerProvider.overrideWith(
          () => _FakeLearningController(session),
        ),
        audioServiceProvider.overrideWith((ref) => audio),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider)
      ..go(AppRoutes.learningSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    expect(find.byType(PitchAccentText), findsNothing);

    await tester.tap(find.widgetWithText(OutlinedButton, '食べる'));
    await tester.pumpAndSettle();
    expect(audio.spokenVocabIds, ['vocab-1']);
    expect(find.byType(PitchAccentText), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
    await tester.pumpAndSettle();
    expect(audio.spokenVocabIds, ['vocab-1', 'vocab-2']);
    expect(find.byType(PitchAccentText), findsNothing);

    await tester.pump();
    expect(audio.spokenVocabIds, ['vocab-1', 'vocab-2']);
  });

  testWidgets('review result renders kana with pitch accent', (tester) async {
    final item = _item(level: 1, pitchAccent: 'HHL');
    final summary = ReviewResultSummary(
      correctAnswers: 1,
      wrongAnswers: 0,
      totalAnswers: 1,
      folderId: 'folder-1',
      words: [
        ReviewAppliedWordResult(
          reviewResult: ReviewWordResult(
            item: item,
            wasDueAtStart: true,
            correctAnswers: 1,
          ),
          oldLevel: 1,
          newLevel: 2,
          nextReviewAt: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: ReviewResultScreen(summary: summary)),
    );

    final reading = tester.widget<PitchAccentReading>(
      find.byType(PitchAccentReading),
    );
    expect(reading.kana, 'たべる');
    expect(reading.pattern, 'HHL');
    expect(tester.takeException(), isNull);
  });

  testWidgets('SRS decision card renders kana with pitch accent',
      (tester) async {
    final item = _item(level: 3, pitchAccent: 'HHL');
    final question = ReviewQuestion(
      item: item,
      type: ReviewQuestionType.chooseWord,
      japaneseText: 'たべる',
      choices: const ['たべる'],
      retryCount: 0,
    );
    final session = ReviewSessionState(
      questions: [question],
      currentIndex: 1,
      resultsByVocabId: {
        item.vocab.id: ReviewWordResult(
          item: item,
          wasDueAtStart: true,
          wrongAnswers: 3,
          srsDecision: ReviewSrsDecision.minusOne,
        ),
      },
      sessionStartTime: 0,
      retryLimit: 2,
      isFinished: true,
      folderId: 'folder-1',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reviewSessionControllerProvider.overrideWith(
            () => _FakeReviewController(session),
          ),
        ],
        child: const MaterialApp(
          home: ReviewSessionScreen(folderId: 'folder-1'),
        ),
      ),
    );
    await tester.pump();

    final reading = tester.widget<PitchAccentReading>(
      find.byType(PitchAccentReading),
    );
    expect(reading.kana, 'たべる');
    expect(reading.pattern, 'HHL');
    expect(find.text('Giảm 1 level'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('guided-write feedback shows details without no-score notice',
      (tester) async {
    final item = _item(
      level: 0,
      example: '毎日ご飯を食べる。',
    );
    final session = LearningSessionState(
      folderId: 'folder-1',
      questions: [
        LearningQuestion(
          item: item,
          type: LearningQuestionType.guidedWrite,
          japaneseText: '食べる',
          choices: const [],
        ),
      ],
      currentIndex: 0,
      resultsByVocabId: {
        item.vocab.id: LearningWordResult(
          item: item,
          totalRequirements: 1,
        ),
      },
      retryLimit: 2,
      quizScript: 'kanji',
    );
    final audio = _FakeAudioService();
    final container = ProviderContainer(
      overrides: [
        routerGuardEnabledProvider.overrideWithValue(false),
        learningControllerProvider.overrideWith(
          () => _FakeLearningController(session),
        ),
        audioServiceProvider.overrideWith((ref) => audio),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider)
      ..go(AppRoutes.learningSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Đã viết xong'));
    await tester.pumpAndSettle();

    expect(find.text('Đáp án'), findsOneWidget);
    expect(find.text('Đáp án đúng'), findsOneWidget);
    expect(find.text('Lượt luyện tập không tính điểm'), findsNothing);
    expect(find.text('毎日ご飯を食べる。'), findsOneWidget);
    expect(find.text('Động từ nhóm 2'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('last learning answer routes directly to the result screen',
      (tester) async {
    final item = _item(level: 0);
    final session = LearningSessionState(
      folderId: 'folder-1',
      questions: [
        LearningQuestion(
          item: item,
          type: LearningQuestionType.chooseWord,
          japaneseText: '食べる',
          choices: const ['食べる', '飲む', '行く', '寝る'],
          requirementId: 'choose-word-1',
        ),
      ],
      currentIndex: 0,
      resultsByVocabId: {
        item.vocab.id: LearningWordResult(
          item: item,
          totalRequirements: 1,
        ),
      },
      retryLimit: 2,
      quizScript: 'kanji',
    );
    final controller = _FakeLearningController(session);
    final audio = _FakeAudioService();
    final container = ProviderContainer(
      overrides: [
        routerGuardEnabledProvider.overrideWithValue(false),
        learningControllerProvider.overrideWith(() => controller),
        audioServiceProvider.overrideWith((ref) => audio),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider)
      ..go(AppRoutes.learningSession);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(OutlinedButton, '食べる'));
    await tester.pumpAndSettle();

    expect(find.text('Xem kết quả'), findsNothing);
    expect(controller.finishCalled, isFalse);

    await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
    await tester.pumpAndSettle();

    expect(controller.finishCalled, isTrue);
    expect(find.text('Kết quả học từ mới'), findsOneWidget);
    expect(find.byType(PitchAccentReading), findsOneWidget);
  });
}

class _FakeLearningController extends LearningController {
  _FakeLearningController(this.initialState);

  final LearningSessionState initialState;
  bool finishCalled = false;

  @override
  AsyncValue<LearningSessionState?> build() => AsyncData(initialState);

  @override
  Future<void> start({
    required String folderId,
    List<String> excludeIds = const [],
  }) async {}

  @override
  Future<void> startWithWords({
    required String folderId,
    required List<VocabWithProgress> words,
  }) async {}

  @override
  Future<LearningResultSummary?> finish() async {
    finishCalled = true;
    final current = state.valueOrNull;
    if (current == null) {
      return null;
    }
    return LearningResultSummary(
      folderId: current.folderId,
      words: current.resultsByVocabId.values.toList(),
    );
  }
}

class _FakeReviewController extends ReviewSessionController {
  _FakeReviewController(this.initialState);

  final ReviewSessionState initialState;

  @override
  AsyncValue<ReviewSessionState?> build() => AsyncData(initialState);
}

class _FakeAudioService extends AudioService {
  final List<String> spokenVocabIds = [];

  @override
  Future<void> speak(VocabularyEntry vocab) async {
    spokenVocabIds.add(vocab.id);
  }

  @override
  Future<void> dispose() async {}
}

VocabWithProgress _item({
  String id = 'vocab-1',
  required int level,
  String meaning = 'ăn',
  String? example,
  String? pitchAccent,
}) {
  return VocabWithProgress(
    vocab: VocabularyEntry(
      id: id,
      folderId: 'folder-1',
      kanji: id == 'vocab-1' ? '食べる' : '飲む',
      kana: id == 'vocab-1' ? 'たべる' : 'のむ',
      romaji: id == 'vocab-1' ? 'taberu' : 'nomu',
      meaning: meaning,
      pitchAccent: pitchAccent,
      example: example,
      note: 'Động từ nhóm 2',
      isFavorite: false,
      createdAt: 0,
    ),
    progress: SrsProgressEntry(
      vocabId: id,
      level: level,
      intervalDays: level == 0 ? 0 : 1,
      nextReviewAt: 0,
      correctCount: 0,
      wrongCount: 0,
    ),
  );
}
