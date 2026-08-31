import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cloud/cloud_store.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/utils/quiz_utils.dart';
import '../../domain/review_models.dart';
import '../../domain/review_repository.dart';

part 'review_session_provider.g.dart';

class ReviewAnswerFeedback {
  const ReviewAnswerFeedback({
    required this.question,
    required this.answer,
    required this.isCorrect,
    this.wasForgotten = false,
  });

  final ReviewQuestion question;
  final String answer;
  final bool isCorrect;
  final bool wasForgotten;
}

@riverpod
ReviewRepository reviewRepository(ReviewRepositoryRef ref) {
  return ReviewRepository(
    store: ref.watch(cloudStoreProvider),
  );
}

@Riverpod(keepAlive: true)
class ReviewSessionController extends _$ReviewSessionController {
  @override
  AsyncValue<ReviewSessionState?> build() => const AsyncData(null);

  Future<void> start({
    String? folderId,
    bool favoritesOnly = false,
    List<String> excludeIds = const [],
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reviewRepositoryProvider).createSession(
            folderId: folderId,
            favoritesOnly: favoritesOnly,
            excludeIds: excludeIds,
          ),
    );
  }

  Future<void> startWithWords(
    List<VocabWithProgress> words, {
    String? folderId,
    bool favoritesOnly = false,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(reviewRepositoryProvider).createSessionFromWords(
            words,
            folderId: folderId,
            favoritesOnly: favoritesOnly,
          ),
    );
  }

  ReviewAnswerFeedback? submitAnswer(String answer) {
    final current = state.valueOrNull;
    final question = current?.currentQuestion;
    if (current == null || question == null || current.isFinished) {
      return null;
    }

    final isCorrect = _isCorrect(question, answer);
    final nextQuestions = [...current.questions];
    final results =
        Map<String, ReviewWordResult>.from(current.resultsByVocabId);
    final vocabId = question.item.vocab.id;
    final previousResult = results[vocabId]!;

    results[vocabId] = previousResult.copyWith(
      correctAnswers: previousResult.correctAnswers + (isCorrect ? 1 : 0),
      wrongAnswers: previousResult.wrongAnswers + (isCorrect ? 0 : 1),
    );

    if (!isCorrect && question.retryCount < current.retryLimit) {
      nextQuestions.add(question.retry());
    }

    final nextIndex = current.currentIndex + 1;
    final isFinished = nextIndex >= nextQuestions.length;
    final nextResults =
        isFinished ? _withDefaultSrsDecisions(results) : results;
    state = AsyncData(
      current.copyWith(
        questions: nextQuestions,
        currentIndex: nextIndex,
        resultsByVocabId: nextResults,
        isFinished: isFinished,
      ),
    );

    return ReviewAnswerFeedback(
      question: question,
      answer: answer,
      isCorrect: isCorrect,
    );
  }

  ReviewAnswerFeedback? forgetCurrentWritingQuestion() {
    final current = state.valueOrNull;
    final question = current?.currentQuestion;
    if (current == null ||
        question == null ||
        current.isFinished ||
        question.type != ReviewQuestionType.write) {
      return null;
    }

    final nextQuestions = [...current.questions];
    final results =
        Map<String, ReviewWordResult>.from(current.resultsByVocabId);
    final vocabId = question.item.vocab.id;
    final previousResult = results[vocabId]!;

    results[vocabId] = previousResult.copyWith(
      wrongAnswers: previousResult.wrongAnswers + 1,
      forceSrsDecision: true,
    );

    if (question.retryCount < current.retryLimit) {
      nextQuestions.add(question.retry());
    }

    final nextIndex = current.currentIndex + 1;
    final isFinished = nextIndex >= nextQuestions.length;
    final nextResults =
        isFinished ? _withDefaultSrsDecisions(results) : results;
    state = AsyncData(
      current.copyWith(
        questions: nextQuestions,
        currentIndex: nextIndex,
        resultsByVocabId: nextResults,
        isFinished: isFinished,
      ),
    );

    return ReviewAnswerFeedback(
      question: question,
      answer: '',
      isCorrect: false,
      wasForgotten: true,
    );
  }

  void setSrsDecision(String vocabId, ReviewSrsDecision decision) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final results =
        Map<String, ReviewWordResult>.from(current.resultsByVocabId);
    final result = results[vocabId];
    if (result == null) {
      return;
    }

    results[vocabId] = result.copyWith(srsDecision: decision);
    state = AsyncData(current.copyWith(resultsByVocabId: results));
  }

  void removeVocabFromCurrentSession(String vocabId) {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }

    final removedBeforeCurrent = current.questions
        .take(current.currentIndex)
        .where((question) => question.item.vocab.id == vocabId)
        .length;
    final nextQuestions = current.questions
        .where((question) => question.item.vocab.id != vocabId)
        .toList();
    final nextResults =
        Map<String, ReviewWordResult>.from(current.resultsByVocabId)
          ..remove(vocabId);

    if (nextQuestions.length == current.questions.length &&
        nextResults.length == current.resultsByVocabId.length) {
      return;
    }

    final nextIndex = (current.currentIndex - removedBeforeCurrent)
        .clamp(0, nextQuestions.length)
        .toInt();
    final isFinished = nextIndex >= nextQuestions.length;
    state = AsyncData(
      current.copyWith(
        questions: nextQuestions,
        currentIndex: nextIndex,
        resultsByVocabId:
            isFinished ? _withDefaultSrsDecisions(nextResults) : nextResults,
        isFinished: isFinished,
      ),
    );
  }

  Future<ReviewResultSummary?> finish() async {
    final current = state.valueOrNull;
    if (current == null || current.pendingSrsDecisions.isNotEmpty) {
      return null;
    }

    state = AsyncData(current.copyWith(isApplying: true));
    final result = await AsyncValue.guard(
      () => ref.read(reviewRepositoryProvider).applyEndSessionSrs(current),
    );

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return null;
    }

    state = AsyncData(current.copyWith(isApplying: false, isFinished: true));
    return result.value;
  }

  bool _isCorrect(ReviewQuestion question, String answer) {
    final japaneseDisplay = question.expectedJapaneseDisplay;
    if (japaneseDisplay != null) {
      return matchesQuizJapaneseText(japaneseDisplay, answer);
    }
    return normalizeQuizAnswer(answer) ==
        normalizeQuizAnswer(question.expectedAnswer);
  }

  Map<String, ReviewWordResult> _withDefaultSrsDecisions(
    Map<String, ReviewWordResult> results,
  ) {
    return {
      for (final entry in results.entries)
        entry.key: entry.value.needsSrsDecision
            ? entry.value.copyWith(srsDecision: ReviewSrsDecision.minusOne)
            : entry.value,
    };
  }
}
