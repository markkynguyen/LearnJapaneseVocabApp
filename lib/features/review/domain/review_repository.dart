import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/constants/srs_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/srs/srs_engine.dart';
import 'review_models.dart';

class ReviewRepository {
  const ReviewRepository({
    required SrsProgressDao srsProgressDao,
    required SettingsDao settingsDao,
  })  : _srsProgressDao = srsProgressDao,
        _settingsDao = settingsDao;

  final SrsProgressDao _srsProgressDao;
  final SettingsDao _settingsDao;

  Future<ReviewSessionState> createSession({
    int? folderId,
    bool favoritesOnly = false,
    List<int> excludeIds = const [],
  }) async {
    final settings = await _settingsDao.getSettings();
    final sessionSize = settings.sessionSize.clamp(1, 100);

    final dueWords = await _srsProgressDao.getDueVocabForSession(
      folderId: folderId,
      limit: sessionSize,
      excludeIds: excludeIds,
      favoritesOnly: favoritesOnly,
    );
    final remaining = sessionSize - dueWords.length;
    final fallbackExcludeIds = {
      ...excludeIds,
      ...dueWords.map((item) => item.vocab.id),
    }.toList();
    final fallbackWords = remaining > 0
        ? await _srsProgressDao.getFallbackVocabForSession(
            folderId: folderId,
            limit: remaining,
            excludeIds: fallbackExcludeIds,
            favoritesOnly: favoritesOnly,
          )
        : <VocabWithProgress>[];

    return _createSessionFromWords(
      [...dueWords, ...fallbackWords],
      settings,
      folderId: folderId,
      favoritesOnly: favoritesOnly,
    );
  }

  Future<ReviewSessionState> createSessionFromWords(
    List<VocabWithProgress> words, {
    int? folderId,
    bool favoritesOnly = false,
  }) async {
    final settings = await _settingsDao.getSettings();
    return _createSessionFromWords(
      words,
      settings,
      folderId: folderId,
      favoritesOnly: favoritesOnly,
    );
  }

  Future<ReviewResultSummary> applyEndSessionSrs(
    ReviewSessionState session,
  ) async {
    final settings = await _settingsDao.getSettings();
    final engine = SrsEngine(
      intervalForLevel: settingsIntervalResolver(settings),
    );
    final applied = <ReviewAppliedWordResult>[];

    for (final result in session.resultsByVocabId.values) {
      final item = result.item;
      final progress = item.progress;
      SrsResult? srsResult;

      if (result.wrongAnswers >= 3 &&
          progress.level == SrsConstants.unlearnedLevel) {
        srsResult = null;
      } else if (result.wrongAnswers >= 3) {
        switch (result.srsDecision) {
          case ReviewSrsDecision.minusOne:
            srsResult = engine.processMinus1(progress);
          case ReviewSrsDecision.reset:
            srsResult = engine.processReset(progress);
          case null:
            continue;
        }
      } else {
        srsResult = engine.processEndSessionSuccess(
          progress,
          isDue: result.wasDueAtStart ||
              progress.level == SrsConstants.unlearnedLevel,
          isMarkedForReview: result.isMarkedForReview,
        );
      }

      await _srsProgressDao.updateProgressByVocabId(
        item.vocab.id,
        SrsProgressCompanion(
          level: srsResult == null
              ? const Value.absent()
              : Value(srsResult.newLevel),
          intervalDays: srsResult == null
              ? const Value.absent()
              : Value(srsResult.newIntervalDays),
          nextReviewAt: srsResult == null
              ? const Value.absent()
              : Value(srsResult.newNextReviewAt),
          correctCount: Value(progress.correctCount + result.correctAnswers),
          wrongCount: Value(progress.wrongCount + result.wrongAnswers),
          lastReviewedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ),
      );

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
    int? folderId,
    bool favoritesOnly = false,
  }) {
    final sessionStartTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final questions = _buildQuestions(words, settings)..shuffle(Random());
    final results = {
      for (final item in words)
        item.vocab.id: ReviewWordResult(
          item: item,
          wasDueAtStart: item.progress.nextReviewAt <= sessionStartTime,
        ),
    };

    return ReviewSessionState(
      questions: questions,
      currentIndex: 0,
      resultsByVocabId: results,
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
    final effectiveTypes =
        types.isEmpty ? [ReviewQuestionType.chooseMeaning] : types;

    return [
      for (final item in words)
        for (final type in effectiveTypes)
          ReviewQuestion(
            item: item,
            type: type,
            choices: _buildChoices(item, type, words),
            retryCount: 0,
          ),
    ];
  }

  List<String> _buildChoices(
    VocabWithProgress item,
    ReviewQuestionType type,
    List<VocabWithProgress> allWords,
  ) {
    if (type != ReviewQuestionType.chooseMeaning &&
        type != ReviewQuestionType.chooseWord &&
        type != ReviewQuestionType.listen) {
      return const [];
    }

    final expected = ReviewQuestion(
      item: item,
      type: type,
      choices: const [],
      retryCount: 0,
    ).expectedAnswer;

    final distractors = allWords
        .where((word) => word.vocab.id != item.vocab.id)
        .map((word) {
          return type == ReviewQuestionType.chooseWord
              ? _displayJapanese(word.vocab)
              : word.vocab.meaning;
        })
        .where((value) => value.trim().isNotEmpty && value != expected)
        .toSet()
        .toList()
      ..shuffle(Random());

    final choices = [expected, ...distractors.take(3)]..shuffle(Random());
    return choices;
  }

  String _displayJapanese(VocabularyEntry vocab) {
    return (vocab.kanji?.trim().isNotEmpty ?? false)
        ? vocab.kanji!.trim()
        : vocab.kana.trim();
  }
}
