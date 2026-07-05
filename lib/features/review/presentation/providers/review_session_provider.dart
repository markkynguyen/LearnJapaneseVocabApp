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
  });

  final ReviewQuestion question;
  final String answer;
  final bool isCorrect;
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
