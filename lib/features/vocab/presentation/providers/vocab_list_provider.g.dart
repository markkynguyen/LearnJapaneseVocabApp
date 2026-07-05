// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vocabListHash() => r'473138acbf86d254679d813ca332bd13f18e434d';

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

/// See also [vocabList].
@ProviderFor(vocabList)
const vocabListProvider = VocabListFamily();

/// See also [vocabList].
class VocabListFamily extends Family<AsyncValue<List<VocabWithProgress>>> {
  /// See also [vocabList].
  const VocabListFamily();

  /// See also [vocabList].
  VocabListProvider call(
    String folderId,
  ) {
    return VocabListProvider(
      folderId,
    );
  }

  @override
  VocabListProvider getProviderOverride(
    covariant VocabListProvider provider,
  ) {
    return call(
      provider.folderId,
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
  String? get name => r'vocabListProvider';
}

/// See also [vocabList].
class VocabListProvider
    extends AutoDisposeFutureProvider<List<VocabWithProgress>> {
  /// See also [vocabList].
  VocabListProvider(
    String folderId,
  ) : this._internal(
          (ref) => vocabList(
            ref as VocabListRef,
            folderId,
          ),
          from: vocabListProvider,
          name: r'vocabListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vocabListHash,
          dependencies: VocabListFamily._dependencies,
          allTransitiveDependencies: VocabListFamily._allTransitiveDependencies,
          folderId: folderId,
        );

  VocabListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.folderId,
  }) : super.internal();

  final String folderId;

  @override
  Override overrideWith(
    FutureOr<List<VocabWithProgress>> Function(VocabListRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VocabListProvider._internal(
        (ref) => create(ref as VocabListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        folderId: folderId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<VocabWithProgress>> createElement() {
    return _VocabListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VocabListProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VocabListRef on AutoDisposeFutureProviderRef<List<VocabWithProgress>> {
  /// The parameter `folderId` of this provider.
  String get folderId;
}

class _VocabListProviderElement
    extends AutoDisposeFutureProviderElement<List<VocabWithProgress>>
    with VocabListRef {
  _VocabListProviderElement(super.provider);

  @override
  String get folderId => (origin as VocabListProvider).folderId;
}

String _$favoriteVocabListHash() => r'121f622829f85be3a84ef5af5d51b9d8b3baf6d5';

/// See also [favoriteVocabList].
@ProviderFor(favoriteVocabList)
const favoriteVocabListProvider = FavoriteVocabListFamily();

/// See also [favoriteVocabList].
class FavoriteVocabListFamily
    extends Family<AsyncValue<List<VocabWithProgress>>> {
  /// See also [favoriteVocabList].
  const FavoriteVocabListFamily();

  /// See also [favoriteVocabList].
  FavoriteVocabListProvider call(
    String folderId,
  ) {
    return FavoriteVocabListProvider(
      folderId,
    );
  }

  @override
  FavoriteVocabListProvider getProviderOverride(
    covariant FavoriteVocabListProvider provider,
  ) {
    return call(
      provider.folderId,
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
  String? get name => r'favoriteVocabListProvider';
}

/// See also [favoriteVocabList].
class FavoriteVocabListProvider
    extends AutoDisposeFutureProvider<List<VocabWithProgress>> {
  /// See also [favoriteVocabList].
  FavoriteVocabListProvider(
    String folderId,
  ) : this._internal(
          (ref) => favoriteVocabList(
            ref as FavoriteVocabListRef,
            folderId,
          ),
          from: favoriteVocabListProvider,
          name: r'favoriteVocabListProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$favoriteVocabListHash,
          dependencies: FavoriteVocabListFamily._dependencies,
          allTransitiveDependencies:
              FavoriteVocabListFamily._allTransitiveDependencies,
          folderId: folderId,
        );

  FavoriteVocabListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.folderId,
  }) : super.internal();

  final String folderId;

  @override
  Override overrideWith(
    FutureOr<List<VocabWithProgress>> Function(FavoriteVocabListRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FavoriteVocabListProvider._internal(
        (ref) => create(ref as FavoriteVocabListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        folderId: folderId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<VocabWithProgress>> createElement() {
    return _FavoriteVocabListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FavoriteVocabListProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FavoriteVocabListRef
    on AutoDisposeFutureProviderRef<List<VocabWithProgress>> {
  /// The parameter `folderId` of this provider.
  String get folderId;
}

class _FavoriteVocabListProviderElement
    extends AutoDisposeFutureProviderElement<List<VocabWithProgress>>
    with FavoriteVocabListRef {
  _FavoriteVocabListProviderElement(super.provider);

  @override
  String get folderId => (origin as FavoriteVocabListProvider).folderId;
}

String _$hasFavoriteVocabHash() => r'de8ce8a5b8e413effb1142027dc9ddafdb2129aa';

/// See also [hasFavoriteVocab].
@ProviderFor(hasFavoriteVocab)
const hasFavoriteVocabProvider = HasFavoriteVocabFamily();

/// See also [hasFavoriteVocab].
class HasFavoriteVocabFamily extends Family<AsyncValue<bool>> {
  /// See also [hasFavoriteVocab].
  const HasFavoriteVocabFamily();

  /// See also [hasFavoriteVocab].
  HasFavoriteVocabProvider call(
    String folderId,
  ) {
    return HasFavoriteVocabProvider(
      folderId,
    );
  }

  @override
  HasFavoriteVocabProvider getProviderOverride(
    covariant HasFavoriteVocabProvider provider,
  ) {
    return call(
      provider.folderId,
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
  String? get name => r'hasFavoriteVocabProvider';
}

/// See also [hasFavoriteVocab].
class HasFavoriteVocabProvider extends AutoDisposeFutureProvider<bool> {
  /// See also [hasFavoriteVocab].
  HasFavoriteVocabProvider(
    String folderId,
  ) : this._internal(
          (ref) => hasFavoriteVocab(
            ref as HasFavoriteVocabRef,
            folderId,
          ),
          from: hasFavoriteVocabProvider,
          name: r'hasFavoriteVocabProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hasFavoriteVocabHash,
          dependencies: HasFavoriteVocabFamily._dependencies,
          allTransitiveDependencies:
              HasFavoriteVocabFamily._allTransitiveDependencies,
          folderId: folderId,
        );

  HasFavoriteVocabProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.folderId,
  }) : super.internal();

  final String folderId;

  @override
  Override overrideWith(
    FutureOr<bool> Function(HasFavoriteVocabRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HasFavoriteVocabProvider._internal(
        (ref) => create(ref as HasFavoriteVocabRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        folderId: folderId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<bool> createElement() {
    return _HasFavoriteVocabProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HasFavoriteVocabProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin HasFavoriteVocabRef on AutoDisposeFutureProviderRef<bool> {
  /// The parameter `folderId` of this provider.
  String get folderId;
}

class _HasFavoriteVocabProviderElement
    extends AutoDisposeFutureProviderElement<bool> with HasFavoriteVocabRef {
  _HasFavoriteVocabProviderElement(super.provider);

  @override
  String get folderId => (origin as HasFavoriteVocabProvider).folderId;
}

String _$folderLevelStatsHash() => r'b889123b90854d78d859921e0d4b7b24a8ceb0b2';

/// See also [folderLevelStats].
@ProviderFor(folderLevelStats)
const folderLevelStatsProvider = FolderLevelStatsFamily();

/// See also [folderLevelStats].
class FolderLevelStatsFamily extends Family<AsyncValue<LevelStats>> {
  /// See also [folderLevelStats].
  const FolderLevelStatsFamily();

  /// See also [folderLevelStats].
  FolderLevelStatsProvider call(
    String folderId,
  ) {
    return FolderLevelStatsProvider(
      folderId,
    );
  }

  @override
  FolderLevelStatsProvider getProviderOverride(
    covariant FolderLevelStatsProvider provider,
  ) {
    return call(
      provider.folderId,
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
  String? get name => r'folderLevelStatsProvider';
}

/// See also [folderLevelStats].
class FolderLevelStatsProvider extends AutoDisposeFutureProvider<LevelStats> {
  /// See also [folderLevelStats].
  FolderLevelStatsProvider(
    String folderId,
  ) : this._internal(
          (ref) => folderLevelStats(
            ref as FolderLevelStatsRef,
            folderId,
          ),
          from: folderLevelStatsProvider,
          name: r'folderLevelStatsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$folderLevelStatsHash,
          dependencies: FolderLevelStatsFamily._dependencies,
          allTransitiveDependencies:
              FolderLevelStatsFamily._allTransitiveDependencies,
          folderId: folderId,
        );

  FolderLevelStatsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.folderId,
  }) : super.internal();

  final String folderId;

  @override
  Override overrideWith(
    FutureOr<LevelStats> Function(FolderLevelStatsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FolderLevelStatsProvider._internal(
        (ref) => create(ref as FolderLevelStatsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        folderId: folderId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<LevelStats> createElement() {
    return _FolderLevelStatsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FolderLevelStatsProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FolderLevelStatsRef on AutoDisposeFutureProviderRef<LevelStats> {
  /// The parameter `folderId` of this provider.
  String get folderId;
}

class _FolderLevelStatsProviderElement
    extends AutoDisposeFutureProviderElement<LevelStats>
    with FolderLevelStatsRef {
  _FolderLevelStatsProviderElement(super.provider);

  @override
  String get folderId => (origin as FolderLevelStatsProvider).folderId;
}

String _$vocabSearchQueryHash() => r'819f803497b08883991564f246677f950933326c';

abstract class _$VocabSearchQuery extends BuildlessAutoDisposeNotifier<String> {
  late final String folderId;

  String build(
    String folderId,
  );
}

/// See also [VocabSearchQuery].
@ProviderFor(VocabSearchQuery)
const vocabSearchQueryProvider = VocabSearchQueryFamily();

/// See also [VocabSearchQuery].
class VocabSearchQueryFamily extends Family<String> {
  /// See also [VocabSearchQuery].
  const VocabSearchQueryFamily();

  /// See also [VocabSearchQuery].
  VocabSearchQueryProvider call(
    String folderId,
  ) {
    return VocabSearchQueryProvider(
      folderId,
    );
  }

  @override
  VocabSearchQueryProvider getProviderOverride(
    covariant VocabSearchQueryProvider provider,
  ) {
    return call(
      provider.folderId,
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
  String? get name => r'vocabSearchQueryProvider';
}

/// See also [VocabSearchQuery].
class VocabSearchQueryProvider
    extends AutoDisposeNotifierProviderImpl<VocabSearchQuery, String> {
  /// See also [VocabSearchQuery].
  VocabSearchQueryProvider(
    String folderId,
  ) : this._internal(
          () => VocabSearchQuery()..folderId = folderId,
          from: vocabSearchQueryProvider,
          name: r'vocabSearchQueryProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vocabSearchQueryHash,
          dependencies: VocabSearchQueryFamily._dependencies,
          allTransitiveDependencies:
              VocabSearchQueryFamily._allTransitiveDependencies,
          folderId: folderId,
        );

  VocabSearchQueryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.folderId,
  }) : super.internal();

  final String folderId;

  @override
  String runNotifierBuild(
    covariant VocabSearchQuery notifier,
  ) {
    return notifier.build(
      folderId,
    );
  }

  @override
  Override overrideWith(VocabSearchQuery Function() create) {
    return ProviderOverride(
      origin: this,
      override: VocabSearchQueryProvider._internal(
        () => create()..folderId = folderId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        folderId: folderId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<VocabSearchQuery, String> createElement() {
    return _VocabSearchQueryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VocabSearchQueryProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VocabSearchQueryRef on AutoDisposeNotifierProviderRef<String> {
  /// The parameter `folderId` of this provider.
  String get folderId;
}

class _VocabSearchQueryProviderElement
    extends AutoDisposeNotifierProviderElement<VocabSearchQuery, String>
    with VocabSearchQueryRef {
  _VocabSearchQueryProviderElement(super.provider);

  @override
  String get folderId => (origin as VocabSearchQueryProvider).folderId;
}

String _$vocabSortHash() => r'a22e30fcb6d5bd6f88b9377c02c295c5353e19a5';

abstract class _$VocabSort extends BuildlessAutoDisposeNotifier<VocabSortMode> {
  late final String folderId;

  VocabSortMode build(
    String folderId,
  );
}

/// See also [VocabSort].
@ProviderFor(VocabSort)
const vocabSortProvider = VocabSortFamily();

/// See also [VocabSort].
class VocabSortFamily extends Family<VocabSortMode> {
  /// See also [VocabSort].
  const VocabSortFamily();

  /// See also [VocabSort].
  VocabSortProvider call(
    String folderId,
  ) {
    return VocabSortProvider(
      folderId,
    );
  }

  @override
  VocabSortProvider getProviderOverride(
    covariant VocabSortProvider provider,
  ) {
    return call(
      provider.folderId,
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
  String? get name => r'vocabSortProvider';
}

/// See also [VocabSort].
class VocabSortProvider
    extends AutoDisposeNotifierProviderImpl<VocabSort, VocabSortMode> {
  /// See also [VocabSort].
  VocabSortProvider(
    String folderId,
  ) : this._internal(
          () => VocabSort()..folderId = folderId,
          from: vocabSortProvider,
          name: r'vocabSortProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vocabSortHash,
          dependencies: VocabSortFamily._dependencies,
          allTransitiveDependencies: VocabSortFamily._allTransitiveDependencies,
          folderId: folderId,
        );

  VocabSortProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.folderId,
  }) : super.internal();

  final String folderId;

  @override
  VocabSortMode runNotifierBuild(
    covariant VocabSort notifier,
  ) {
    return notifier.build(
      folderId,
    );
  }

  @override
  Override overrideWith(VocabSort Function() create) {
    return ProviderOverride(
      origin: this,
      override: VocabSortProvider._internal(
        () => create()..folderId = folderId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        folderId: folderId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<VocabSort, VocabSortMode> createElement() {
    return _VocabSortProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VocabSortProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VocabSortRef on AutoDisposeNotifierProviderRef<VocabSortMode> {
  /// The parameter `folderId` of this provider.
  String get folderId;
}

class _VocabSortProviderElement
    extends AutoDisposeNotifierProviderElement<VocabSort, VocabSortMode>
    with VocabSortRef {
  _VocabSortProviderElement(super.provider);

  @override
  String get folderId => (origin as VocabSortProvider).folderId;
}

String _$vocabListControllerHash() =>
    r'c68a09edbc755b0c8722b3ab54b5ece0d7c2ad33';

/// See also [VocabListController].
@ProviderFor(VocabListController)
final vocabListControllerProvider =
    AutoDisposeAsyncNotifierProvider<VocabListController, void>.internal(
  VocabListController.new,
  name: r'vocabListControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$vocabListControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VocabListController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
