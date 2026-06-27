// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$learningRepositoryHash() =>
    r'562ad358b34c8f6d7673845a7dd9f66b9d926f2c';

/// See also [learningRepository].
@ProviderFor(learningRepository)
final learningRepositoryProvider =
    AutoDisposeProvider<LearningRepository>.internal(
  learningRepository,
  name: r'learningRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$learningRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef LearningRepositoryRef = AutoDisposeProviderRef<LearningRepository>;
String _$learningControllerHash() =>
    r'60fc121835a9c57a89ef313494f61b0994eca7c2';

/// See also [LearningController].
@ProviderFor(LearningController)
final learningControllerProvider = NotifierProvider<LearningController,
    AsyncValue<LearningSessionState?>>.internal(
  LearningController.new,
  name: r'learningControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$learningControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$LearningController = Notifier<AsyncValue<LearningSessionState?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
