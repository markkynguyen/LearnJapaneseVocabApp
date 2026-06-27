import 'dart:math';

import 'package:drift/drift.dart';

import '../../../core/constants/srs_constants.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/quiz_utils.dart';
import 'learning_models.dart';

class LearningRepository {
  const LearningRepository({
    required SrsProgressDao srsProgressDao,
    required SettingsDao settingsDao,
  })  : _srsProgressDao = srsProgressDao,
        _settingsDao = settingsDao;

  final SrsProgressDao _srsProgressDao;
  final SettingsDao _settingsDao;

  Future<LearningSessionState> createSession({
    required int folderId,
    List<int> excludeIds = const [],
  }) async {
    final settings = await _settingsDao.getSettings();
    final words = await _srsProgressDao.getNewVocabForLearning(
      folderId: folderId,
      limit: settings.newWordSessionSize.clamp(1, 100),
      excludeIds: excludeIds,
    );
    return _createSession(folderId, words, settings);
  }

  Future<LearningSessionState> createSessionFromWords({
    required int folderId,
    required List<VocabWithProgress> words,
  }) async {
    final settings = await _settingsDao.getSettings();
    return _createSession(folderId, words, settings);
  }

  Future<LearningResultSummary> applyResults(
    LearningSessionState session,
  ) async {
    final settings = await _settingsDao.getSettings();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final interval = settings.srsLevel1IntervalDays;

    for (final result in session.resultsByVocabId.values) {
      final progress = result.item.progress;
      await _srsProgressDao.updateProgressByVocabId(
        result.item.vocab.id,
        SrsProgressCompanion(
          level: Value(
            result.passed ? SrsConstants.minLevel : SrsConstants.unlearnedLevel,
          ),
          intervalDays: Value(result.passed ? interval : 0),
          nextReviewAt: Value(
            result.passed
                ? now + (interval * SrsConstants.secondsPerDay).round()
                : 0,
          ),
          correctCount: Value(progress.correctCount + result.correctAnswers),
          wrongCount: Value(progress.wrongCount + result.wrongAnswers),
          lastReviewedAt: Value(now),
        ),
      );
    }

    return LearningResultSummary(
      folderId: session.folderId,
      words: session.resultsByVocabId.values.toList(),
    );
  }

  Future<LearningSessionState> _createSession(
    int folderId,
    List<VocabWithProgress> words,
    AppSettings settings,
  ) async {
    final wordIds = words.map((word) => word.vocab.id).toList();
    final sameFolder = await _srsProgressDao.getLearnedVocabForDistractors(
      folderId: folderId,
      limit: 50,
      excludeIds: wordIds,
    );
    final usedIds = {...wordIds, ...sameFolder.map((word) => word.vocab.id)};
    final global = await _srsProgressDao.getLearnedVocabForDistractors(
      limit: 50,
      excludeIds: usedIds.toList(),
    );
    final pool = [...words, ...sameFolder, ...global];
    final questions = _buildQuestions(words, pool, settings);
    final requirementCounts = <int, int>{};
    for (final question in questions) {
      if (question.requirementId != null) {
        requirementCounts.update(
          question.item.vocab.id,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
      }
    }

    return LearningSessionState(
      folderId: folderId,
      questions: questions,
      currentIndex: 0,
      resultsByVocabId: {
        for (final word in words)
          word.vocab.id: LearningWordResult(
            item: word,
            totalRequirements: requirementCounts[word.vocab.id] ?? 0,
          ),
      },
      retryLimit: settings.quizRetryLimit,
      quizScript: settings.quizJapaneseScript,
    );
  }

  List<LearningQuestion> _buildQuestions(
    List<VocabWithProgress> words,
    List<VocabWithProgress> pool,
    AppSettings settings,
  ) {
    final guided = <LearningQuestion>[];
    final graded = <LearningQuestion>[];
    final hasConfiguredQuestions = settings.newWordListenCount > 0 ||
        settings.newWordWriteCount > 0 ||
        settings.newWordChooseWordCount > 0 ||
        settings.newWordChooseMeaningCount > 0;

    for (final item in words) {
      final japanese = japaneseForQuiz(item.vocab, settings.quizJapaneseScript);
      if (settings.newWordWriteCount > 0) {
        guided.add(
          LearningQuestion(
            item: item,
            type: LearningQuestionType.guidedWrite,
            japaneseText: japanese,
            choices: const [],
          ),
        );
      }

      void addQuestions(LearningQuestionType type, int count) {
        for (var index = 0; index < count; index++) {
          graded.add(
            LearningQuestion(
              item: item,
              type: type,
              japaneseText: japanese,
              choices: _buildChoices(item, type, pool, settings),
              requirementId: '${item.vocab.id}-${type.name}-$index',
            ),
          );
        }
      }

      if (hasConfiguredQuestions) {
        addQuestions(
          LearningQuestionType.listen,
          settings.newWordListenCount,
        );
        addQuestions(
          LearningQuestionType.write,
          settings.newWordWriteCount,
        );
        addQuestions(
          LearningQuestionType.chooseWord,
          settings.newWordChooseWordCount,
        );
        addQuestions(
          LearningQuestionType.chooseMeaning,
          settings.newWordChooseMeaningCount,
        );
      } else {
        addQuestions(LearningQuestionType.chooseMeaning, 1);
      }
    }

    graded.shuffle(Random());
    return [...guided, ...graded];
  }

  List<String> _buildChoices(
    VocabWithProgress item,
    LearningQuestionType type,
    List<VocabWithProgress> pool,
    AppSettings settings,
  ) {
    if (type != LearningQuestionType.listen &&
        type != LearningQuestionType.chooseWord &&
        type != LearningQuestionType.chooseMeaning) {
      return const [];
    }
    final expected = type == LearningQuestionType.chooseWord
        ? japaneseForQuiz(item.vocab, settings.quizJapaneseScript)
        : item.vocab.meaning;
    final candidateValues =
        pool.where((candidate) => candidate.vocab.id != item.vocab.id).map(
              (candidate) => type == LearningQuestionType.chooseWord
                  ? japaneseForQuiz(
                      candidate.vocab,
                      settings.quizJapaneseScript,
                    )
                  : candidate.vocab.meaning,
            );
    return buildPrioritizedLearningChoices(
      expected: expected,
      candidateValues: candidateValues,
    );
  }
}

List<String> buildPrioritizedLearningChoices({
  required String expected,
  required Iterable<String> candidateValues,
  Random? random,
}) {
  final seen = <String>{expected};
  final distractors = <String>[];
  for (final value in candidateValues) {
    final normalized = value.trim();
    if (normalized.isEmpty || !seen.add(normalized)) {
      continue;
    }
    distractors.add(normalized);
    if (distractors.length == 3) {
      break;
    }
  }

  return [expected, ...distractors]..shuffle(random ?? Random());
}
