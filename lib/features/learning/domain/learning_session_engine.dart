import '../../../core/utils/quiz_utils.dart';
import 'learning_models.dart';

class LearningSubmissionResult {
  const LearningSubmissionResult({
    required this.state,
    required this.feedback,
  });

  final LearningSessionState state;
  final LearningAnswerFeedback feedback;
}

LearningSessionState revealLearningHint(LearningSessionState session) {
  final question = session.currentQuestion;
  if (question == null ||
      question.type != LearningQuestionType.write ||
      question.hintUsed) {
    return session;
  }

  final questions = [...session.questions];
  questions[session.currentIndex] = question.copyWith(hintUsed: true);
  return session.copyWith(questions: questions);
}

LearningSubmissionResult? submitLearningAnswer(
  LearningSessionState session,
  String answer,
) {
  final question = session.currentQuestion;
  if (question == null || session.isFinished) {
    return null;
  }

  final questions = [...session.questions];
  final results = Map<String, LearningWordResult>.from(
    session.resultsByVocabId,
  );
  final result = results[question.item.vocab.id]!;
  final isCorrect = question.isGuided ||
      question.hintUsed ||
      normalizeQuizAnswer(answer) ==
          normalizeQuizAnswer(question.expectedAnswer);

  if (question.hintUsed) {
    questions.add(question.copyWith(hintUsed: false));
  } else if (!question.isGuided && isCorrect) {
    final completed = {...result.completedRequirements};
    final requirementId = question.requirementId;
    if (requirementId != null) {
      completed.add(requirementId);
    }
    results[question.item.vocab.id] = result.copyWith(
      completedRequirements: completed,
      correctAnswers: result.correctAnswers + 1,
    );
  } else if (!question.isGuided) {
    results[question.item.vocab.id] = result.copyWith(
      wrongAnswers: result.wrongAnswers + 1,
    );
    if (question.retryCount < session.retryLimit) {
      questions.add(question.retry());
    }
  }

  return LearningSubmissionResult(
    state: session.copyWith(
      questions: questions,
      currentIndex: session.currentIndex + 1,
      resultsByVocabId: results,
    ),
    feedback: LearningAnswerFeedback(
      question: question,
      answer: answer,
      isCorrect: isCorrect,
      wasGraded: question.isGraded,
    ),
  );
}
