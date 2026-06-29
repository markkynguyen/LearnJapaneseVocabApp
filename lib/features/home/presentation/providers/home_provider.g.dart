// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$greetingHash() => r'd342873cee31b1c6b7a1581a40b16d4cf838102b';

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
String _$totalDueCountHash() => r'3a700376e1acc5568d9a34e6e38631cfef83238f';

/// See also [totalDueCount].
@ProviderFor(totalDueCount)
final totalDueCountProvider = AutoDisposeStreamProvider<int>.internal(
  totalDueCount,
  name: r'totalDueCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalDueCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalDueCountRef = AutoDisposeStreamProviderRef<int>;
String _$totalLevelStatsHash() => r'ef091f123914bfd806d834a8c1848af2eed8f97b';

/// See also [totalLevelStats].
@ProviderFor(totalLevelStats)
final totalLevelStatsProvider = AutoDisposeStreamProvider<LevelStats>.internal(
  totalLevelStats,
  name: r'totalLevelStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$totalLevelStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef TotalLevelStatsRef = AutoDisposeStreamProviderRef<LevelStats>;
String _$homeVocabSuggestionsHash() =>
    r'2b2834a2e7ed8b8ba5c3f0a7b6582fd17174a74b';

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
    extends AutoDisposeStreamProvider<List<VocabSearchResult>> {
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
    Stream<List<VocabSearchResult>> Function(HomeVocabSuggestionsRef provider)
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
  AutoDisposeStreamProviderElement<List<VocabSearchResult>> createElement() {
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
    on AutoDisposeStreamProviderRef<List<VocabSearchResult>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _HomeVocabSuggestionsProviderElement
    extends AutoDisposeStreamProviderElement<List<VocabSearchResult>>
    with HomeVocabSuggestionsRef {
  _HomeVocabSuggestionsProviderElement(super.provider);

  @override
  String get query => (origin as HomeVocabSuggestionsProvider).query;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
