import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/learning_models.dart';
import '../../domain/learning_repository.dart';
import '../../domain/learning_session_engine.dart';

part 'learning_provider.g.dart';

@riverpod
LearningRepository learningRepository(LearningRepositoryRef ref) {
  return LearningRepository(
    srsProgressDao: ref.watch(srsProgressDaoProvider),
    settingsDao: ref.watch(settingsDaoProvider),
  );
}

@Riverpod(keepAlive: true)
class LearningController extends _$LearningController {
  @override
  AsyncValue<LearningSessionState?> build() => const AsyncData(null);

  Future<void> start({
    required int folderId,
    List<int> excludeIds = const [],
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(learningRepositoryProvider).createSession(
            folderId: folderId,
            excludeIds: excludeIds,
          ),
    );
  }

  Future<void> startWithWords({
    required int folderId,
    required List<VocabWithProgress> words,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(learningRepositoryProvider).createSessionFromWords(
            folderId: folderId,
            words: words,
          ),
    );
  }

  void revealHint() {
    final current = state.valueOrNull;
    if (current == null) {
      return;
    }
    state = AsyncData(revealLearningHint(current));
  }

  LearningAnswerFeedback? submitAnswer(String answer) {
    final current = state.valueOrNull;
    if (current == null) {
      return null;
    }
    final submission = submitLearningAnswer(current, answer);
    if (submission == null) {
      return null;
    }
    state = AsyncData(submission.state);
    return submission.feedback;
  }

  Future<LearningResultSummary?> finish() async {
    final current = state.valueOrNull;
    if (current == null || !current.isFinished) {
      return null;
    }
    state = AsyncData(current.copyWith(isApplying: true));
    final result = await AsyncValue.guard(
      () => ref.read(learningRepositoryProvider).applyResults(current),
    );
    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      return null;
    }
    state = AsyncData(current.copyWith(isApplying: false));
    return result.value;
  }
}
