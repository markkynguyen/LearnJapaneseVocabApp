// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewRepositoryHash() => r'6091dfe2c09ae9482cccb8478f123fb9ef19cd42';

/// See also [reviewRepository].
@ProviderFor(reviewRepository)
final reviewRepositoryProvider = AutoDisposeProvider<ReviewRepository>.internal(
  reviewRepository,
  name: r'reviewRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reviewRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ReviewRepositoryRef = AutoDisposeProviderRef<ReviewRepository>;
String _$reviewSessionControllerHash() =>
    r'c252b1f3e8e0d2174c5027d99808758a7a7935e5';

/// See also [ReviewSessionController].
@ProviderFor(ReviewSessionController)
final reviewSessionControllerProvider = NotifierProvider<
    ReviewSessionController, AsyncValue<ReviewSessionState?>>.internal(
  ReviewSessionController.new,
  name: r'reviewSessionControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reviewSessionControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ReviewSessionController = Notifier<AsyncValue<ReviewSessionState?>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
