import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/review/domain/review_models.dart';
import 'package:jvocab/features/review/presentation/providers/review_session_provider.dart';

void main() {
  test('remove vocab deletes all questions and results for that vocab', () {
    final first = _item('vocab-1');
    final second = _item('vocab-2');
    final firstWrite = _question(first, ReviewQuestionType.write);
    final firstMeaning = _question(first, ReviewQuestionType.chooseMeaning);
    final secondMeaning = _question(second, ReviewQuestionType.chooseMeaning);
    final controller = _controller(
      ReviewSessionState(
        questions: [
          firstWrite,
          firstMeaning,
          secondMeaning,
          firstWrite.retry(),
        ],
        currentIndex: 2,
        resultsByVocabId: {
          first.vocab.id: ReviewWordResult(
            item: first,
            wasDueAtStart: true,
            correctAnswers: 1,
            wrongAnswers: 1,
          ),
          second.vocab.id: ReviewWordResult(
            item: second,
            wasDueAtStart: true,
          ),
        },
        sessionStartTime: 0,
        retryLimit: 2,
        isFinished: false,
      ),
    );

    controller.removeVocabFromCurrentSession(first.vocab.id);

    final state = controller.state.valueOrNull!;
    expect(state.questions, [secondMeaning]);
    expect(state.currentIndex, 0);
    expect(state.resultsByVocabId.keys, [second.vocab.id]);
    expect(state.correctAnswers, 0);
    expect(state.wrongAnswers, 0);
    expect(state.isFinished, isFalse);
  });

  test('remove answered vocab clears its score from the current session', () {
    final first = _item('vocab-1');
    final second = _item('vocab-2');
    final controller = _controller(
      ReviewSessionState(
        questions: [
          _question(first, ReviewQuestionType.chooseMeaning),
          _question(second, ReviewQuestionType.chooseMeaning),
        ],
        currentIndex: 1,
        resultsByVocabId: {
          first.vocab.id: ReviewWordResult(
            item: first,
            wasDueAtStart: true,
            correctAnswers: 1,
          ),
          second.vocab.id: ReviewWordResult(
            item: second,
            wasDueAtStart: true,
          ),
        },
        sessionStartTime: 0,
        retryLimit: 2,
        isFinished: false,
      ),
    );

    controller.removeVocabFromCurrentSession(first.vocab.id);

    final state = controller.state.valueOrNull!;
    expect(state.currentQuestion?.item.vocab.id, second.vocab.id);
    expect(state.correctAnswers, 0);
    expect(state.wrongAnswers, 0);
    expect(state.resultsByVocabId.containsKey(first.vocab.id), isFalse);
  });

  test('remove last vocab leaves the session finished', () {
    final item = _item('vocab-1');
    final controller = _controller(
      ReviewSessionState(
        questions: [_question(item, ReviewQuestionType.chooseMeaning)],
        currentIndex: 1,
        resultsByVocabId: {
          item.vocab.id: ReviewWordResult(
            item: item,
            wasDueAtStart: true,
            correctAnswers: 1,
          ),
        },
        sessionStartTime: 0,
        retryLimit: 2,
        isFinished: true,
      ),
    );

    controller.removeVocabFromCurrentSession(item.vocab.id);

    final state = controller.state.valueOrNull!;
    expect(state.questions, isEmpty);
    expect(state.resultsByVocabId, isEmpty);
    expect(state.currentIndex, 0);
    expect(state.isFinished, isTrue);
  });
}

ReviewSessionController _controller(ReviewSessionState state) {
  final controller = _FakeReviewController(state);
  final container = ProviderContainer(
    overrides: [
      reviewSessionControllerProvider.overrideWith(() => controller),
    ],
  );
  addTearDown(container.dispose);
  return container.read(reviewSessionControllerProvider.notifier);
}

class _FakeReviewController extends ReviewSessionController {
  _FakeReviewController(this.initialState);

  final ReviewSessionState initialState;

  @override
  AsyncValue<ReviewSessionState?> build() => AsyncData(initialState);
}

ReviewQuestion _question(VocabWithProgress item, ReviewQuestionType type) {
  return ReviewQuestion(
    item: item,
    type: type,
    japaneseText: item.vocab.kana,
    choices: type == ReviewQuestionType.write ? const [] : [item.vocab.meaning],
    retryCount: 0,
  );
}

VocabWithProgress _item(String id) {
  return VocabWithProgress(
    vocab: VocabularyEntry(
      id: id,
      folderId: 'folder-1',
      kanji: id == 'vocab-1' ? '食べる' : '飲む',
      kana: id == 'vocab-1' ? 'たべる' : 'のむ',
      romaji: id == 'vocab-1' ? 'taberu' : 'nomu',
      meaning: id == 'vocab-1' ? 'ăn' : 'uống',
      isFavorite: false,
      createdAt: 0,
    ),
    progress: SrsProgressEntry(
      vocabId: id,
      level: 1,
      intervalDays: 1,
      nextReviewAt: 0,
      correctCount: 0,
      wrongCount: 0,
    ),
  );
}
