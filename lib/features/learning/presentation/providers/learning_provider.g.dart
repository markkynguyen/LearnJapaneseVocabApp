// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$learningRepositoryHash() =>
    r'eeb99d3dae06c381730067135b667dd70241a870';

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
    r'7e27e34affbc908295aee5a53701fb98e3629a6c';

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
