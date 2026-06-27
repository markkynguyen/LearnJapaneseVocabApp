import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/database/app_database.dart';
import 'package:jvocab/core/utils/quiz_utils.dart';
import 'package:jvocab/features/home/presentation/providers/home_provider.dart';
import 'package:jvocab/features/learning/domain/learning_models.dart';
import 'package:jvocab/features/learning/domain/learning_repository.dart';
import 'package:jvocab/features/learning/domain/learning_session_engine.dart';

void main() {
  test('guided write advances without counting an answer', () {
    final item = _item();
    final state = _session(
      item,
      [
        _question(item, LearningQuestionType.guidedWrite),
        _question(item, LearningQuestionType.write, requirementId: 'write-1'),
      ],
    );

    final submission = submitLearningAnswer(state, '食べる')!;
    final result = submission.state.resultsByVocabId[item.vocab.id]!;

    expect(submission.feedback.wasGraded, isFalse);
    expect(submission.state.currentIndex, 1);
    expect(result.correctAnswers, 0);
    expect(result.wrongAnswers, 0);
    expect(result.passed, isFalse);
  });

  test('using a hint appends an unhinted replacement to the queue', () {
    final item = _item();
    final state = _session(
      item,
      [_question(item, LearningQuestionType.write, requirementId: 'write-1')],
    );

    final hinted = revealLearningHint(state);
    final practice = submitLearningAnswer(hinted, 'anything')!;

    expect(practice.feedback.wasGraded, isFalse);
    expect(practice.state.questions, hasLength(2));
    expect(practice.state.currentQuestion!.hintUsed, isFalse);
    expect(
      practice.state.resultsByVocabId[item.vocab.id]!.correctAnswers,
      0,
    );

    final graded = submitLearningAnswer(practice.state, '食べる')!;
    expect(graded.state.resultsByVocabId[item.vocab.id]!.passed, isTrue);
  });

  test('a correct retry passes while exhausting retries keeps level 0 result',
      () {
    final item = _item();
    final question = _question(
      item,
      LearningQuestionType.chooseMeaning,
      requirementId: 'meaning-1',
    );
    final initial = _session(item, [question], retryLimit: 1);

    final wrongThenRetry = submitLearningAnswer(initial, 'wrong')!;
    final recovered = submitLearningAnswer(wrongThenRetry.state, 'ăn')!;
    expect(recovered.state.resultsByVocabId[item.vocab.id]!.passed, isTrue);
    expect(
      recovered.state.resultsByVocabId[item.vocab.id]!.wrongAnswers,
      1,
    );

    final wrongOnce = submitLearningAnswer(initial, 'wrong')!;
    final exhausted = submitLearningAnswer(wrongOnce.state, 'still wrong')!;
    final failed = exhausted.state.resultsByVocabId[item.vocab.id]!;
    expect(exhausted.state.isFinished, isTrue);
    expect(failed.passed, isFalse);
    expect(failed.wrongAnswers, 2);
  });

  test('quiz script uses kana or kanji with kana fallback', () {
    final item = _item();
    final kanaOnly = _item(id: 2, kanji: null);

    expect(japaneseForQuiz(item.vocab, quizScriptKanji), '食べる');
    expect(japaneseForQuiz(item.vocab, quizScriptKana), 'たべる');
    expect(japaneseForQuiz(kanaOnly.vocab, quizScriptKanji), 'たべる');
  });

  test('distractors keep priority and remove duplicates', () {
    final choices = buildPrioritizedLearningChoices(
      expected: 'ăn',
      candidateValues: ['uống', 'uống', 'ngủ', 'đi', 'đến'],
      random: Random(1),
    );

    expect(choices, hasLength(4));
    expect(choices, containsAll(['ăn', 'uống', 'ngủ', 'đi']));
    expect(choices, isNot(contains('đến')));
  });

  test('folder completion is learned words divided by total words', () {
    const summary = FolderSummary(
      folder: Folder(
        id: 1,
        name: 'N5',
        description: null,
        color: '#000000',
        createdAt: 0,
      ),
      totalWords: 10,
      unlearnedCount: 4,
      dueCount: 2,
      lv6Count: 1,
    );
    final empty = FolderSummary(
      folder: summary.folder,
      totalWords: 0,
      unlearnedCount: 0,
      dueCount: 0,
      lv6Count: 0,
    );

    expect(summary.completionRate, 0.6);
    expect(empty.completionRate, 0);
  });
}

VocabWithProgress _item({int id = 1, String? kanji = '食べる'}) {
  return VocabWithProgress(
    vocab: VocabularyEntry(
      id: id,
      folderId: 1,
      kanji: kanji,
      kana: 'たべる',
      romaji: 'taberu',
      meaning: 'ăn',
      note: 'động từ',
      isFavorite: false,
      createdAt: 0,
    ),
    progress: SrsProgressEntry(
      id: id,
      vocabId: id,
      level: 0,
      intervalDays: 0,
      nextReviewAt: 0,
      correctCount: 0,
      wrongCount: 0,
    ),
  );
}

LearningQuestion _question(
  VocabWithProgress item,
  LearningQuestionType type, {
  String? requirementId,
}) {
  return LearningQuestion(
    item: item,
    type: type,
    japaneseText: '食べる',
    choices: const [],
    requirementId: requirementId,
  );
}

LearningSessionState _session(
  VocabWithProgress item,
  List<LearningQuestion> questions, {
  int retryLimit = 2,
}) {
  final requirements = questions.where((item) => item.requirementId != null);
  return LearningSessionState(
    folderId: 1,
    questions: questions,
    currentIndex: 0,
    resultsByVocabId: {
      item.vocab.id: LearningWordResult(
        item: item,
        totalRequirements: requirements.length,
      ),
    },
    retryLimit: retryLimit,
    quizScript: quizScriptKanji,
  );
}
