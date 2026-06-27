// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_session_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewRepositoryHash() => r'5e98cfa9cd447f95d522cbc3fc7b1da9865a1628';

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
    r'b98c1750261b117cbda97ed7417548075c723a86';

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
