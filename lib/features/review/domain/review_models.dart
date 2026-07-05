import '../../../core/constants/srs_constants.dart';
import '../../../core/models/app_models.dart';

enum ReviewQuestionType {
  listen,
  write,
  chooseWord,
  chooseMeaning;

  String get label {
    switch (this) {
      case ReviewQuestionType.listen:
        return 'Nghe';
      case ReviewQuestionType.write:
        return 'Viết';
      case ReviewQuestionType.chooseWord:
        return 'Chọn từ';
      case ReviewQuestionType.chooseMeaning:
        return 'Chọn nghĩa';
    }
  }
}

class ReviewQuestion {
  const ReviewQuestion({
    required this.item,
    required this.type,
    required this.japaneseText,
    required this.choices,
    required this.retryCount,
  });

  final VocabWithProgress item;
  final ReviewQuestionType type;
  final String japaneseText;
  final List<String> choices;
  final int retryCount;

  String get expectedAnswer {
    final vocab = item.vocab;
    switch (type) {
      case ReviewQuestionType.listen:
      case ReviewQuestionType.chooseMeaning:
        return vocab.meaning;
      case ReviewQuestionType.write:
      case ReviewQuestionType.chooseWord:
        return japaneseText;
    }
  }

  String get prompt {
    final vocab = item.vocab;
    switch (type) {
      case ReviewQuestionType.listen:
        return 'Nghe phát âm và chọn nghĩa đúng';
      case ReviewQuestionType.write:
      case ReviewQuestionType.chooseWord:
        return vocab.meaning;
      case ReviewQuestionType.chooseMeaning:
        return japaneseText;
    }
  }

  ReviewQuestion retry() {
    return ReviewQuestion(
      item: item,
      type: type,
      japaneseText: japaneseText,
      choices: choices,
      retryCount: retryCount + 1,
    );
  }
}

class ReviewWordResult {
  const ReviewWordResult({
    required this.item,
    required this.wasDueAtStart,
    this.correctAnswers = 0,
    this.wrongAnswers = 0,
    this.srsDecision,
  });

  final VocabWithProgress item;
  final bool wasDueAtStart;
  final int correctAnswers;
  final int wrongAnswers;
  final ReviewSrsDecision? srsDecision;

  bool get isMarkedForReview => wrongAnswers > 0;
  bool get requiresSrsDecision =>
      wrongAnswers >= 3 && item.progress.level != SrsConstants.unlearnedLevel;
  bool get needsSrsDecision => requiresSrsDecision && srsDecision == null;

  ReviewWordResult copyWith({
    int? correctAnswers,
    int? wrongAnswers,
    ReviewSrsDecision? srsDecision,
  }) {
    return ReviewWordResult(
      item: item,
      wasDueAtStart: wasDueAtStart,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      srsDecision: srsDecision ?? this.srsDecision,
    );
  }
}

enum ReviewSrsDecision {
  minusOne,
  reset,
}

class ReviewSessionState {
  const ReviewSessionState({
    required this.questions,
    required this.currentIndex,
    required this.resultsByVocabId,
    required this.sessionStartTime,
    required this.retryLimit,
    required this.isFinished,
    this.folderId,
    this.favoritesOnly = false,
    this.isApplying = false,
  });

  final List<ReviewQuestion> questions;
  final int currentIndex;
  final Map<String, ReviewWordResult> resultsByVocabId;
  final int sessionStartTime;
  final int retryLimit;
  final bool isFinished;
  final String? folderId;
  final bool favoritesOnly;
  final bool isApplying;

  ReviewQuestion? get currentQuestion {
    if (questions.isEmpty || currentIndex >= questions.length) {
      return null;
    }
    return questions[currentIndex];
  }

  int get totalQuestions => questions.length;
  int get answeredQuestions => currentIndex.clamp(0, questions.length);
  int get correctAnswers => resultsByVocabId.values
      .fold(0, (sum, result) => sum + result.correctAnswers);
  int get wrongAnswers => resultsByVocabId.values
      .fold(0, (sum, result) => sum + result.wrongAnswers);

  List<ReviewWordResult> get pendingSrsDecisions {
    return resultsByVocabId.values
        .where((result) => result.needsSrsDecision)
        .toList();
  }

  List<ReviewWordResult> get srsDecisionWords {
    return resultsByVocabId.values
        .where((result) => result.requiresSrsDecision)
        .toList();
  }

  ReviewSessionState copyWith({
    List<ReviewQuestion>? questions,
    int? currentIndex,
    Map<String, ReviewWordResult>? resultsByVocabId,
    bool? isFinished,
    bool? isApplying,
  }) {
    return ReviewSessionState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      resultsByVocabId: resultsByVocabId ?? this.resultsByVocabId,
      sessionStartTime: sessionStartTime,
      retryLimit: retryLimit,
      isFinished: isFinished ?? this.isFinished,
      folderId: folderId,
      favoritesOnly: favoritesOnly,
      isApplying: isApplying ?? this.isApplying,
    );
  }
}

class ReviewAppliedWordResult {
  const ReviewAppliedWordResult({
    required this.reviewResult,
    required this.oldLevel,
    this.newLevel,
    this.nextReviewAt,
    this.message,
  });

  final ReviewWordResult reviewResult;
  final int oldLevel;
  final int? newLevel;
  final int? nextReviewAt;
  final String? message;

  bool get hasWrongAnswers => reviewResult.wrongAnswers > 0;
  bool get didLevelUp => newLevel != null && newLevel! > oldLevel;
  bool get didChangeSrs => newLevel != null && nextReviewAt != null;
}

class ReviewResultSummary {
  const ReviewResultSummary({
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalAnswers,
    required this.words,
    this.folderId,
    this.favoritesOnly = false,
  });

  final int correctAnswers;
  final int wrongAnswers;
  final int totalAnswers;
  final List<ReviewAppliedWordResult> words;
  final String? folderId;
  final bool favoritesOnly;

  int get percentage {
    if (totalAnswers == 0) {
      return 0;
    }
    return ((correctAnswers / totalAnswers) * 100).round();
  }

  List<ReviewAppliedWordResult> get wrongWords {
    return words.where((word) => word.hasWrongAnswers).toList();
  }

  List<ReviewAppliedWordResult> get leveledUpWords {
    return words.where((word) => word.didLevelUp).toList();
  }
}
