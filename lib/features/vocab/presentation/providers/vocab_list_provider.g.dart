// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vocabListHash() => r'50407eaf628eb6f8b5a179b6ea343e86052c6c0e';

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
    int folderId,
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
    extends AutoDisposeStreamProvider<List<VocabWithProgress>> {
  /// See also [vocabList].
  VocabListProvider(
    int folderId,
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

  final int folderId;

  @override
  Override overrideWith(
    Stream<List<VocabWithProgress>> Function(VocabListRef provider) create,
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
  AutoDisposeStreamProviderElement<List<VocabWithProgress>> createElement() {
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

mixin VocabListRef on AutoDisposeStreamProviderRef<List<VocabWithProgress>> {
  /// The parameter `folderId` of this provider.
  int get folderId;
}

class _VocabListProviderElement
    extends AutoDisposeStreamProviderElement<List<VocabWithProgress>>
    with VocabListRef {
  _VocabListProviderElement(super.provider);

  @override
  int get folderId => (origin as VocabListProvider).folderId;
}

String _$favoriteVocabListHash() => r'f7c3284dde1113e6b55ee7705ce4efd7500e640f';

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
    int folderId,
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
    extends AutoDisposeStreamProvider<List<VocabWithProgress>> {
  /// See also [favoriteVocabList].
  FavoriteVocabListProvider(
    int folderId,
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

  final int folderId;

  @override
  Override overrideWith(
    Stream<List<VocabWithProgress>> Function(FavoriteVocabListRef provider)
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
  AutoDisposeStreamProviderElement<List<VocabWithProgress>> createElement() {
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
    on AutoDisposeStreamProviderRef<List<VocabWithProgress>> {
  /// The parameter `folderId` of this provider.
  int get folderId;
}

class _FavoriteVocabListProviderElement
    extends AutoDisposeStreamProviderElement<List<VocabWithProgress>>
    with FavoriteVocabListRef {
  _FavoriteVocabListProviderElement(super.provider);

  @override
  int get folderId => (origin as FavoriteVocabListProvider).folderId;
}

String _$hasFavoriteVocabHash() => r'5f00e7c11322fe5e106842ff49b3bd20d072fc14';

/// See also [hasFavoriteVocab].
@ProviderFor(hasFavoriteVocab)
const hasFavoriteVocabProvider = HasFavoriteVocabFamily();

/// See also [hasFavoriteVocab].
class HasFavoriteVocabFamily extends Family<AsyncValue<bool>> {
  /// See also [hasFavoriteVocab].
  const HasFavoriteVocabFamily();

  /// See also [hasFavoriteVocab].
  HasFavoriteVocabProvider call(
    int folderId,
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
class HasFavoriteVocabProvider extends AutoDisposeStreamProvider<bool> {
  /// See also [hasFavoriteVocab].
  HasFavoriteVocabProvider(
    int folderId,
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

  final int folderId;

  @override
  Override overrideWith(
    Stream<bool> Function(HasFavoriteVocabRef provider) create,
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
  AutoDisposeStreamProviderElement<bool> createElement() {
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

mixin HasFavoriteVocabRef on AutoDisposeStreamProviderRef<bool> {
  /// The parameter `folderId` of this provider.
  int get folderId;
}

class _HasFavoriteVocabProviderElement
    extends AutoDisposeStreamProviderElement<bool> with HasFavoriteVocabRef {
  _HasFavoriteVocabProviderElement(super.provider);

  @override
  int get folderId => (origin as HasFavoriteVocabProvider).folderId;
}

String _$folderLevelStatsHash() => r'f248867e47466541b6ff316fe87c70fa1d24d739';

/// See also [folderLevelStats].
@ProviderFor(folderLevelStats)
const folderLevelStatsProvider = FolderLevelStatsFamily();

/// See also [folderLevelStats].
class FolderLevelStatsFamily extends Family<AsyncValue<LevelStats>> {
  /// See also [folderLevelStats].
  const FolderLevelStatsFamily();

  /// See also [folderLevelStats].
  FolderLevelStatsProvider call(
    int folderId,
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
class FolderLevelStatsProvider extends AutoDisposeStreamProvider<LevelStats> {
  /// See also [folderLevelStats].
  FolderLevelStatsProvider(
    int folderId,
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

  final int folderId;

  @override
  Override overrideWith(
    Stream<LevelStats> Function(FolderLevelStatsRef provider) create,
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
  AutoDisposeStreamProviderElement<LevelStats> createElement() {
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

mixin FolderLevelStatsRef on AutoDisposeStreamProviderRef<LevelStats> {
  /// The parameter `folderId` of this provider.
  int get folderId;
}

class _FolderLevelStatsProviderElement
    extends AutoDisposeStreamProviderElement<LevelStats>
    with FolderLevelStatsRef {
  _FolderLevelStatsProviderElement(super.provider);

  @override
  int get folderId => (origin as FolderLevelStatsProvider).folderId;
}

String _$vocabSearchQueryHash() => r'96c6eb735a612e0385a092f01b392eb96a14559a';

abstract class _$VocabSearchQuery extends BuildlessAutoDisposeNotifier<String> {
  late final int folderId;

  String build(
    int folderId,
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
    int folderId,
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
    int folderId,
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

  final int folderId;

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
  int get folderId;
}

class _VocabSearchQueryProviderElement
    extends AutoDisposeNotifierProviderElement<VocabSearchQuery, String>
    with VocabSearchQueryRef {
  _VocabSearchQueryProviderElement(super.provider);

  @override
  int get folderId => (origin as VocabSearchQueryProvider).folderId;
}

String _$vocabSortHash() => r'b12374887a2e0b06830130faf2156a10bff9f075';

abstract class _$VocabSort extends BuildlessAutoDisposeNotifier<VocabSortMode> {
  late final int folderId;

  VocabSortMode build(
    int folderId,
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
    int folderId,
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
    int folderId,
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

  final int folderId;

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
  int get folderId;
}

class _VocabSortProviderElement
    extends AutoDisposeNotifierProviderElement<VocabSort, VocabSortMode>
    with VocabSortRef {
  _VocabSortProviderElement(super.provider);

  @override
  int get folderId => (origin as VocabSortProvider).folderId;
}

String _$vocabListControllerHash() =>
    r'954113ae1a6be5fcaf694f29755f3b4874a1af71';

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
