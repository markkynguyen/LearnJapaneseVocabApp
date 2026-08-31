import 'dart:math';

import '../../../core/cloud/cloud_store.dart';
import '../../../core/constants/srs_constants.dart';
import '../../../core/models/app_models.dart';
import '../../../core/srs/srs_engine.dart';
import '../../../core/utils/quiz_utils.dart';
import 'review_models.dart';

class ReviewRepository {
  const ReviewRepository({required CloudStore store}) : _store = store;
  final CloudStore _store;

  Future<ReviewSessionState> createSession({
    String? folderId,
    bool favoritesOnly = false,
    List<String> excludeIds = const [],
  }) async {
    final settings = await _store.getLearningSettings();
    final all = folderId == null
        ? await _store.getAllVocab()
        : await _store.getVocabByFolder(
            folderId,
            favoritesOnly: favoritesOnly,
          );
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final available = all.where(
      (item) =>
          !excludeIds.contains(item.vocab.id) &&
          (!favoritesOnly || item.vocab.isFavorite),
    );
    final due = available
        .where(
          (item) =>
              item.progress.level > 0 && item.progress.nextReviewAt <= now,
        )
        .toList()
      ..sort(
        (a, b) => a.progress.nextReviewAt.compareTo(b.progress.nextReviewAt),
      );
    final selected = due.take(settings.sessionSize).toList();
    if (selected.length < settings.sessionSize) {
      final used = selected.map((item) => item.vocab.id).toSet();
      final fallback = available
          .where(
            (item) => item.progress.level > 0 && !used.contains(item.vocab.id),
          )
          .toList()
        ..sort(
          (a, b) => (a.progress.lastReviewedAt ?? 0)
              .compareTo(b.progress.lastReviewedAt ?? 0),
        );
      selected.addAll(fallback.take(settings.sessionSize - selected.length));
    }
    return _createSessionFromWords(
      selected,
      settings,
      folderId: folderId,
      favoritesOnly: favoritesOnly,
    );
  }

  Future<ReviewSessionState> createSessionFromWords(
    List<VocabWithProgress> words, {
    String? folderId,
    bool favoritesOnly = false,
  }) async =>
      _createSessionFromWords(
        words,
        await _store.getLearningSettings(),
        folderId: folderId,
        favoritesOnly: favoritesOnly,
      );

  Future<ReviewResultSummary> applyEndSessionSrs(
    ReviewSessionState session,
  ) async {
    final settings = await _store.getLearningSettings();
    final engine =
        SrsEngine(intervalForLevel: settingsIntervalResolver(settings));
    final applied = <ReviewAppliedWordResult>[];
    final updates = <SrsProgressEntry>[];
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    for (final result in session.resultsByVocabId.values) {
      final item = result.item;
      final progress = item.progress;
      SrsResult? srsResult;
      if (result.requiresSrsDecision) {
        srsResult = switch (result.srsDecision) {
          ReviewSrsDecision.minusOne => engine.processMinus1(progress),
          ReviewSrsDecision.reset => engine.processReset(progress),
          null => null,
        };
        if (result.srsDecision == null) continue;
      } else if (result.wrongAnswers > 0 &&
          result.wasDueAtStart &&
          progress.level > SrsConstants.unlearnedLevel) {
        srsResult = engine.processReviewedSameLevel(progress);
      } else if (result.wrongAnswers < 3) {
        srsResult = engine.processEndSessionSuccess(
          progress,
          isDue: result.wasDueAtStart ||
              progress.level == SrsConstants.unlearnedLevel,
          isMarkedForReview: result.isMarkedForReview,
        );
      }
      final next = progress.copyWith(
        level: srsResult?.newLevel ?? progress.level,
        intervalDays: srsResult?.newIntervalDays ?? progress.intervalDays,
        nextReviewAt: srsResult?.newNextReviewAt ?? progress.nextReviewAt,
        correctCount: progress.correctCount + result.correctAnswers,
        wrongCount: progress.wrongCount + result.wrongAnswers,
        lastReviewedAt: now,
      );
      updates.add(next);
      applied.add(
        ReviewAppliedWordResult(
          reviewResult: result,
          oldLevel: progress.level,
          newLevel: srsResult?.newLevel,
          nextReviewAt: srsResult?.newNextReviewAt,
          message: srsResult?.message,
        ),
      );
    }
    await _store.applySrsUpdates(updates);
    return ReviewResultSummary(
      correctAnswers: session.correctAnswers,
      wrongAnswers: session.wrongAnswers,
      totalAnswers: session.correctAnswers + session.wrongAnswers,
      words: applied,
      folderId: session.folderId,
      favoritesOnly: session.favoritesOnly,
    );
  }

  ReviewSessionState _createSessionFromWords(
    List<VocabWithProgress> words,
    AppSettings settings, {
    String? folderId,
    bool favoritesOnly = false,
  }) {
    final sessionStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final questions = _prioritizeWriteQuestions(
      _buildQuestions(words, settings),
    );
    return ReviewSessionState(
      questions: questions,
      currentIndex: 0,
      resultsByVocabId: {
        for (final item in words)
          item.vocab.id: ReviewWordResult(
            item: item,
            wasDueAtStart: item.progress.nextReviewAt <= sessionStartTime,
          ),
      },
      sessionStartTime: sessionStartTime,
      retryLimit: settings.quizRetryLimit,
      isFinished: questions.isEmpty,
      folderId: folderId,
      favoritesOnly: favoritesOnly,
    );
  }

  List<ReviewQuestion> _buildQuestions(
    List<VocabWithProgress> words,
    AppSettings settings,
  ) {
    final types = <ReviewQuestionType>[
      for (var i = 0; i < settings.quizListenCount; i++)
        ReviewQuestionType.listen,
      for (var i = 0; i < settings.quizWriteCount; i++)
        ReviewQuestionType.write,
      for (var i = 0; i < settings.quizChooseWordCount; i++)
        ReviewQuestionType.chooseWord,
      for (var i = 0; i < settings.quizChooseMeaningCount; i++)
        ReviewQuestionType.chooseMeaning,
    ];
    final effective =
        types.isEmpty ? [ReviewQuestionType.chooseMeaning] : types;
    return [
      for (final item in words)
        for (final type in effective)
          ReviewQuestion(
            item: item,
            type: type,
            japaneseDisplay:
                japaneseDisplayForQuiz(item.vocab, settings.quizJapaneseScript),
            choices: _choices(item, type, words, settings),
            retryCount: 0,
          ),
    ];
  }

  List<ReviewQuestion> _prioritizeWriteQuestions(
    List<ReviewQuestion> questions,
  ) {
    final writeQuestions = questions
        .where((question) => question.type == ReviewQuestionType.write)
        .toList()
      ..shuffle(Random());
    final otherQuestions = questions
        .where((question) => question.type != ReviewQuestionType.write)
        .toList()
      ..shuffle(Random());
    return [...writeQuestions, ...otherQuestions];
  }

  List<QuizChoice> _choices(
    VocabWithProgress item,
    ReviewQuestionType type,
    List<VocabWithProgress> words,
    AppSettings settings,
  ) {
    if (type != ReviewQuestionType.chooseMeaning &&
        type != ReviewQuestionType.chooseWord &&
        type != ReviewQuestionType.listen) {
      return const [];
    }
    if (type == ReviewQuestionType.chooseWord) {
      final expectedDisplay =
          japaneseDisplayForQuiz(item.vocab, settings.quizJapaneseScript);
      final candidateDisplays = words
          .where((word) => word.vocab.id != item.vocab.id)
          .map(
            (word) =>
                japaneseDisplayForQuiz(word.vocab, settings.quizJapaneseScript),
          )
          .where((display) => display.primary != expectedDisplay.primary);
      return _buildJapaneseChoices(expectedDisplay, candidateDisplays);
    }

    final expected = item.vocab.meaning;
    final distractors = words
        .where((word) => word.vocab.id != item.vocab.id)
        .map((word) => word.vocab.meaning)
        .where((value) => value.trim().isNotEmpty && value != expected)
        .toSet()
        .toList()
      ..shuffle(Random());
    final choices = [expected, ...distractors.take(3)]..shuffle(Random());
    return choices.map((value) => QuizChoice(value: value)).toList();
  }

  List<QuizChoice> _buildJapaneseChoices(
    QuizJapaneseText expected,
    Iterable<QuizJapaneseText> candidateDisplays,
  ) {
    final byValue = <String, QuizJapaneseText>{expected.primary: expected};
    for (final display in candidateDisplays) {
      if (display.primary.trim().isNotEmpty) {
        byValue.putIfAbsent(display.primary, () => display);
      }
    }
    final distractors = byValue.keys
        .where((value) => value != expected.primary)
        .toList()
      ..shuffle(Random());
    final values = [expected.primary, ...distractors.take(3)]..shuffle(Random());
    return values
        .map(
          (value) => QuizChoice(
            value: value,
            japaneseDisplay: byValue[value],
          ),
        )
        .toList();
  }
}
