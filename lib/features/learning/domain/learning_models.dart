import '../../../core/models/app_models.dart';

enum LearningQuestionType {
  listen,
  guidedWrite,
  write,
  chooseWord,
  chooseMeaning;

  String get label => switch (this) {
        LearningQuestionType.listen => 'Nghe',
        LearningQuestionType.guidedWrite => 'Viết mẫu',
        LearningQuestionType.write => 'Viết',
        LearningQuestionType.chooseWord => 'Chọn từ',
        LearningQuestionType.chooseMeaning => 'Chọn nghĩa',
      };
}

class LearningQuestion {
  const LearningQuestion({
    required this.item,
    required this.type,
    required this.japaneseText,
    required this.choices,
    this.requirementId,
    this.retryCount = 0,
    this.hintUsed = false,
  });

  final VocabWithProgress item;
  final LearningQuestionType type;
  final String japaneseText;
  final List<String> choices;
  final String? requirementId;
  final int retryCount;
  final bool hintUsed;

  bool get isGuided => type == LearningQuestionType.guidedWrite;
  bool get isGraded => !isGuided && !hintUsed;

  String get expectedAnswer => switch (type) {
        LearningQuestionType.listen ||
        LearningQuestionType.chooseMeaning =>
          item.vocab.meaning,
        LearningQuestionType.guidedWrite ||
        LearningQuestionType.write ||
        LearningQuestionType.chooseWord =>
          japaneseText,
      };

  String get prompt => switch (type) {
        LearningQuestionType.listen => 'Nghe phát âm và chọn nghĩa đúng',
        LearningQuestionType.guidedWrite => item.vocab.meaning,
        LearningQuestionType.write => item.vocab.meaning,
        LearningQuestionType.chooseWord => item.vocab.meaning,
        LearningQuestionType.chooseMeaning => japaneseText,
      };

  LearningQuestion retry() => copyWith(retryCount: retryCount + 1);

  LearningQuestion copyWith({
    int? retryCount,
    bool? hintUsed,
  }) {
    return LearningQuestion(
      item: item,
      type: type,
      japaneseText: japaneseText,
      choices: choices,
      requirementId: requirementId,
      retryCount: retryCount ?? this.retryCount,
      hintUsed: hintUsed ?? this.hintUsed,
    );
  }
}

class LearningWordResult {
  const LearningWordResult({
    required this.item,
    required this.totalRequirements,
    this.completedRequirements = const {},
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
  });

  final VocabWithProgress item;
  final int totalRequirements;
  final Set<String> completedRequirements;
  final int correctAnswers;
  final int wrongAnswers;

  bool get passed =>
      totalRequirements > 0 &&
      completedRequirements.length >= totalRequirements;

  LearningWordResult copyWith({
    Set<String>? completedRequirements,
    int? correctAnswers,
    int? wrongAnswers,
  }) {
    return LearningWordResult(
      item: item,
      totalRequirements: totalRequirements,
      completedRequirements:
          completedRequirements ?? this.completedRequirements,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
    );
  }
}

class LearningSessionState {
  const LearningSessionState({
    required this.folderId,
    required this.questions,
    required this.currentIndex,
    required this.resultsByVocabId,
    required this.retryLimit,
    required this.quizScript,
    this.isApplying = false,
  });

  final String folderId;
  final List<LearningQuestion> questions;
  final int currentIndex;
  final Map<String, LearningWordResult> resultsByVocabId;
  final int retryLimit;
  final String quizScript;
  final bool isApplying;

  List<VocabWithProgress> get words =>
      resultsByVocabId.values.map((result) => result.item).toList();
  LearningQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;
  bool get isFinished => currentIndex >= questions.length;

  LearningSessionState copyWith({
    List<LearningQuestion>? questions,
    int? currentIndex,
    Map<String, LearningWordResult>? resultsByVocabId,
    bool? isApplying,
  }) {
    return LearningSessionState(
      folderId: folderId,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      resultsByVocabId: resultsByVocabId ?? this.resultsByVocabId,
      retryLimit: retryLimit,
      quizScript: quizScript,
      isApplying: isApplying ?? this.isApplying,
    );
  }
}

class LearningAnswerFeedback {
  const LearningAnswerFeedback({
    required this.question,
    required this.answer,
    required this.isCorrect,
    required this.wasGraded,
  });

  final LearningQuestion question;
  final String answer;
  final bool isCorrect;
  final bool wasGraded;
}

class LearningResultSummary {
  const LearningResultSummary({
    required this.folderId,
    required this.words,
  });

  final String folderId;
  final List<LearningWordResult> words;

  List<LearningWordResult> get passedWords =>
      words.where((word) => word.passed).toList();
  List<LearningWordResult> get failedWords =>
      words.where((word) => !word.passed).toList();
}

class LearningPreviewRequest {
  const LearningPreviewRequest({
    this.excludeIds = const [],
    this.words,
  });

  final List<String> excludeIds;
  final List<VocabWithProgress>? words;
}
