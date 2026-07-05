import 'dart:math';

import '../../../core/cloud/cloud_store.dart';
import '../../../core/constants/srs_constants.dart';
import '../../../core/models/app_models.dart';
import '../../../core/utils/quiz_utils.dart';
import 'learning_models.dart';

class LearningRepository {
  const LearningRepository({required CloudStore store}) : _store = store;
  final CloudStore _store;

  Future<LearningSessionState> createSession({
    required String folderId,
    List<String> excludeIds = const [],
  }) async {
    final settings = await _store.getLearningSettings();
    final words = (await _store.getVocabByFolder(folderId))
        .where(
          (item) =>
              item.progress.level == SrsConstants.unlearnedLevel &&
              !excludeIds.contains(item.vocab.id),
        )
        .take(settings.newWordSessionSize.clamp(1, 100))
        .toList();
    return _createSession(folderId, words, settings);
  }

  Future<LearningSessionState> createSessionFromWords({
    required String folderId,
    required List<VocabWithProgress> words,
  }) async =>
      _createSession(folderId, words, await _store.getLearningSettings());

  Future<LearningResultSummary> applyResults(
    LearningSessionState session,
  ) async {
    final settings = await _store.getLearningSettings();
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final interval = settings.srsLevel1IntervalDays;
    final updates = <SrsProgressEntry>[];
    for (final result in session.resultsByVocabId.values) {
      final progress = result.item.progress;
      updates.add(
        progress.copyWith(
          level: result.passed
              ? SrsConstants.minLevel
              : SrsConstants.unlearnedLevel,
          intervalDays: result.passed ? interval : 0,
          nextReviewAt: result.passed
              ? now + (interval * SrsConstants.secondsPerDay).round()
              : 0,
          correctCount: progress.correctCount + result.correctAnswers,
          wrongCount: progress.wrongCount + result.wrongAnswers,
          lastReviewedAt: now,
        ),
      );
    }
    await _store.applySrsUpdates(updates);
    return LearningResultSummary(
      folderId: session.folderId,
      words: session.resultsByVocabId.values.toList(),
    );
  }

  Future<LearningSessionState> _createSession(
    String folderId,
    List<VocabWithProgress> words,
    AppSettings settings,
  ) async {
    final wordIds = words.map((word) => word.vocab.id).toSet();
    final sameFolder = (await _store.getVocabByFolder(folderId))
        .where(
          (word) => word.progress.level > 0 && !wordIds.contains(word.vocab.id),
        )
        .take(50)
        .toList();
    final usedIds = {...wordIds, ...sameFolder.map((word) => word.vocab.id)};
    final global = (await _store.getAllVocab())
        .where(
          (word) => word.progress.level > 0 && !usedIds.contains(word.vocab.id),
        )
        .take(50)
        .toList();
    final pool = [...words, ...sameFolder, ...global];
    final questions = _buildQuestions(words, pool, settings);
    final requirementCounts = <String, int>{};
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
    final configured = settings.newWordListenCount > 0 ||
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
      void add(LearningQuestionType type, int count) {
        for (var index = 0; index < count; index++) {
          graded.add(
            LearningQuestion(
              item: item,
              type: type,
              japaneseText: japanese,
              choices: _choices(item, type, pool, settings),
              requirementId: '${item.vocab.id}-${type.name}-$index',
            ),
          );
        }
      }

      if (configured) {
        add(LearningQuestionType.listen, settings.newWordListenCount);
        add(LearningQuestionType.write, settings.newWordWriteCount);
        add(LearningQuestionType.chooseWord, settings.newWordChooseWordCount);
        add(
          LearningQuestionType.chooseMeaning,
          settings.newWordChooseMeaningCount,
        );
      } else {
        add(LearningQuestionType.chooseMeaning, 1);
      }
    }
    graded.shuffle(Random());
    return [...guided, ...graded];
  }

  List<String> _choices(
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
    return buildPrioritizedLearningChoices(
      expected: expected,
      candidateValues: pool
          .where((candidate) => candidate.vocab.id != item.vocab.id)
          .map(
            (candidate) => type == LearningQuestionType.chooseWord
                ? japaneseForQuiz(candidate.vocab, settings.quizJapaneseScript)
                : candidate.vocab.meaning,
          ),
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
    if (normalized.isEmpty || !seen.add(normalized)) continue;
    distractors.add(normalized);
    if (distractors.length == 3) break;
  }
  return [expected, ...distractors]..shuffle(random ?? Random());
}
