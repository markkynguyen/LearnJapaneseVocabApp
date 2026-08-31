import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/core/utils/quiz_utils.dart';
import 'package:jvocab/features/folders/presentation/widgets/folder_progress_list.dart';
import 'package:jvocab/features/learning/domain/learning_models.dart';
import 'package:jvocab/features/learning/domain/learning_repository.dart';
import 'package:jvocab/features/learning/domain/learning_session_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    final kanaOnly = _item(id: 'vocab-2', kanji: null);
    final matchingKanji = _item(id: 'vocab-3', kanji: 'たべる');

    expect(japaneseForQuiz(item.vocab, quizScriptKanji), '食べる');
    expect(japaneseForQuiz(item.vocab, quizScriptKana), 'たべる');
    expect(japaneseForQuiz(kanaOnly.vocab, quizScriptKanji), 'たべる');

    final both = japaneseDisplayForQuiz(item.vocab, quizScriptBoth);
    expect(both.primary, '食べる');
    expect(both.secondary, 'たべる');
    expect(both.acceptedAnswers, ['食べる', 'たべる']);
    expect(matchesJapaneseAnswer(item.vocab, quizScriptBoth, '食べる'), isTrue);
    expect(matchesJapaneseAnswer(item.vocab, quizScriptBoth, 'たべる'), isTrue);

    final kanaOnlyBoth = japaneseDisplayForQuiz(kanaOnly.vocab, quizScriptBoth);
    expect(kanaOnlyBoth.primary, 'たべる');
    expect(kanaOnlyBoth.secondary, isNull);

    final matchingBoth =
        japaneseDisplayForQuiz(matchingKanji.vocab, quizScriptBoth);
    expect(matchingBoth.primary, 'たべる');
    expect(matchingBoth.secondary, isNull);
  });

  test('both-script writing accepts either kanji or kana', () {
    final item = _item();
    final question = LearningQuestion(
      item: item,
      type: LearningQuestionType.write,
      japaneseDisplay: japaneseDisplayForQuiz(item.vocab, quizScriptBoth),
      choices: const [],
      requirementId: 'write-1',
    );
    final state = _session(item, [question]);

    final kanjiSubmission = submitLearningAnswer(state, '食べる')!;
    final kanaSubmission = submitLearningAnswer(state, 'たべる')!;

    expect(kanjiSubmission.feedback.isCorrect, isTrue);
    expect(kanaSubmission.feedback.isCorrect, isTrue);
  });

  test('both-script learning repository keeps paired japanese display',
      () async {
    final item = _item();
    final distractor = _item(
      id: 'vocab-2',
      kanji: '飲む',
      kana: 'のむ',
      meaning: 'uống',
      level: 1,
    );
    final store = _FakeLearningStore(
      settings: const AppSettings(
        newWordListenCount: 0,
        newWordWriteCount: 1,
        newWordChooseWordCount: 1,
        newWordChooseMeaningCount: 1,
        quizJapaneseScript: quizScriptBoth,
      ),
      folderWords: [item, distractor],
    );
    final repository = LearningRepository(store: store);

    final session = await repository.createSessionFromWords(
      folderId: 'folder-1',
      words: [item],
    );

    final chooseMeaning = session.questions.firstWhere(
      (question) => question.type == LearningQuestionType.chooseMeaning,
    );
    expect(chooseMeaning.promptJapaneseDisplay?.primary, '食べる');
    expect(chooseMeaning.promptJapaneseDisplay?.secondary, 'たべる');

    final chooseWord = session.questions.firstWhere(
      (question) => question.type == LearningQuestionType.chooseWord,
    );
    final correctChoice = chooseWord.choices.singleWhere(
      (choice) => choice.value == '食べる',
    );
    expect(correctChoice.japaneseDisplay?.primary, '食べる');
    expect(correctChoice.japaneseDisplay?.secondary, 'たべる');
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
    const summary = FolderWithCount(
      folder: Folder(
        id: 'folder-1',
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
    final empty = FolderWithCount(
      folder: summary.folder,
      totalWords: 0,
      unlearnedCount: 0,
      dueCount: 0,
      lv6Count: 0,
    );

    expect(folderCompletionRate(summary), 0.6);
    expect(folderCompletionRate(empty), 0);
  });
}

class _FakeLearningStore extends CloudStore {
  _FakeLearningStore({
    required this.settings,
    this.folderWords = const [],
  }) : super(
          SupabaseClient(
            'https://example.supabase.co',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  final AppSettings settings;
  final List<VocabWithProgress> folderWords;

  @override
  Future<AppSettings> getLearningSettings() async => settings;

  @override
  Future<List<VocabWithProgress>> getVocabByFolder(
    String folderId, {
    VocabSortMode sortMode = VocabSortMode.newest,
    String searchQuery = '',
    bool favoritesOnly = false,
  }) async =>
      folderWords;

  @override
  Future<List<VocabWithProgress>> getAllVocab({
    bool activeOnly = true,
  }) async =>
      const [];
}

VocabWithProgress _item({
  String id = 'vocab-1',
  String? kanji = '食べる',
  String kana = 'たべる',
  String meaning = 'ăn',
  int level = 0,
}) {
  return VocabWithProgress(
    vocab: VocabularyEntry(
      id: id,
      folderId: 'folder-1',
      kanji: kanji,
      kana: kana,
      romaji: 'taberu',
      meaning: meaning,
      note: 'động từ',
      isFavorite: false,
      createdAt: 0,
    ),
    progress: SrsProgressEntry(
      vocabId: id,
      level: level,
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
    folderId: 'folder-1',
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
