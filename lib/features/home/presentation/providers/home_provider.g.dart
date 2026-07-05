// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$greetingHash() => r'2e4d1f163174058aa6515bb455e0d63114ae0e20';

/// See also [greeting].
@ProviderFor(greeting)
final greetingProvider = AutoDisposeProvider<String>.internal(
  greeting,
  name: r'greetingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$greetingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef GreetingRef = AutoDisposeProviderRef<String>;
String _$totalDueCountHash() => r'244f7ab4f4f7bde5cc2059b867859e13d5171e38';

/// See also [totalDueCount].
@ProviderFor(totalDueCount)
final totalDueCountProvider = AutoDisposeFutureProvider<int>.internal(
  totalDueCount,
  name: r'totalDueCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalDueCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalDueCountRef = AutoDisposeFutureProviderRef<int>;
String _$totalLevelStatsHash() => r'539ed4f0423111755b45c00c73a1a1ff2a571015';

/// See also [totalLevelStats].
@ProviderFor(totalLevelStats)
final totalLevelStatsProvider = AutoDisposeFutureProvider<LevelStats>.internal(
  totalLevelStats,
  name: r'totalLevelStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalLevelStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalLevelStatsRef = AutoDisposeFutureProviderRef<LevelStats>;
String _$homeVocabSuggestionsHash() =>
    r'6c9c778a9a6ae1f2f98401a93d7637e7c1092d27';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [homeVocabSuggestions].
@ProviderFor(homeVocabSuggestions)
const homeVocabSuggestionsProvider = HomeVocabSuggestionsFamily();

/// See also [homeVocabSuggestions].
class HomeVocabSuggestionsFamily
    extends Family<AsyncValue<List<VocabSearchResult>>> {
  /// See also [homeVocabSuggestions].
  const HomeVocabSuggestionsFamily();

  /// See also [homeVocabSuggestions].
  HomeVocabSuggestionsProvider call(
    String query,
  ) {
    return HomeVocabSuggestionsProvider(
      query,
    );
  }

  @override
  HomeVocabSuggestionsProvider getProviderOverride(
    covariant HomeVocabSuggestionsProvider provider,
  ) {
    return call(
      provider.query,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'homeVocabSuggestionsProvider';
}

/// See also [homeVocabSuggestions].
class HomeVocabSuggestionsProvider
    extends AutoDisposeFutureProvider<List<VocabSearchResult>> {
  /// See also [homeVocabSuggestions].
  HomeVocabSuggestionsProvider(
    String query,
  ) : this._internal(
          (ref) => homeVocabSuggestions(
            ref as HomeVocabSuggestionsRef,
            query,
          ),
          from: homeVocabSuggestionsProvider,
          name: r'homeVocabSuggestionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$homeVocabSuggestionsHash,
          dependencies: HomeVocabSuggestionsFamily._dependencies,
          allTransitiveDependencies:
              HomeVocabSuggestionsFamily._allTransitiveDependencies,
          query: query,
        );

  HomeVocabSuggestionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<VocabSearchResult>> Function(HomeVocabSuggestionsRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HomeVocabSuggestionsProvider._internal(
        (ref) => create(ref as HomeVocabSuggestionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<VocabSearchResult>> createElement() {
    return _HomeVocabSuggestionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HomeVocabSuggestionsProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin HomeVocabSuggestionsRef
    on AutoDisposeFutureProviderRef<List<VocabSearchResult>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _HomeVocabSuggestionsProviderElement
    extends AutoDisposeFutureProviderElement<List<VocabSearchResult>>
    with HomeVocabSuggestionsRef {
  _HomeVocabSuggestionsProviderElement(super.provider);

  @override
  String get query => (origin as HomeVocabSuggestionsProvider).query;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
