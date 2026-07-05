// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$folderRepositoryHash() => r'538c3d5f5b185d1dd236c6f100d7fbeb9e938085';

/// See also [folderRepository].
@ProviderFor(folderRepository)
final folderRepositoryProvider = AutoDisposeProvider<FolderRepository>.internal(
  folderRepository,
  name: r'folderRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$folderRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FolderRepositoryRef = AutoDisposeProviderRef<FolderRepository>;
String _$foldersHash() => r'3f4fa92b16f7db57a2b18c9b55df7eaf52d437d2';

/// See also [folders].
@ProviderFor(folders)
final foldersProvider =
    AutoDisposeFutureProvider<List<FolderWithCount>>.internal(
  folders,
  name: r'foldersProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$foldersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FoldersRef = AutoDisposeFutureProviderRef<List<FolderWithCount>>;
String _$folderByIdHash() => r'14f87cba71c37ecc103d5e8f06b7b2ef77efeaba';

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

/// See also [folderById].
@ProviderFor(folderById)
const folderByIdProvider = FolderByIdFamily();

/// See also [folderById].
class FolderByIdFamily extends Family<AsyncValue<Folder?>> {
  /// See also [folderById].
  const FolderByIdFamily();

  /// See also [folderById].
  FolderByIdProvider call(
    String id,
  ) {
    return FolderByIdProvider(
      id,
    );
  }

  @override
  FolderByIdProvider getProviderOverride(
    covariant FolderByIdProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'folderByIdProvider';
}

/// See also [folderById].
class FolderByIdProvider extends AutoDisposeFutureProvider<Folder?> {
  /// See also [folderById].
  FolderByIdProvider(
    String id,
  ) : this._internal(
          (ref) => folderById(
            ref as FolderByIdRef,
            id,
          ),
          from: folderByIdProvider,
          name: r'folderByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$folderByIdHash,
          dependencies: FolderByIdFamily._dependencies,
          allTransitiveDependencies:
              FolderByIdFamily._allTransitiveDependencies,
          id: id,
        );

  FolderByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Folder?> Function(FolderByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FolderByIdProvider._internal(
        (ref) => create(ref as FolderByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Folder?> createElement() {
    return _FolderByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FolderByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FolderByIdRef on AutoDisposeFutureProviderRef<Folder?> {
  /// The parameter `id` of this provider.
  String get id;
}

class _FolderByIdProviderElement
    extends AutoDisposeFutureProviderElement<Folder?> with FolderByIdRef {
  _FolderByIdProviderElement(super.provider);

  @override
  String get id => (origin as FolderByIdProvider).id;
}

String _$folderControllerHash() => r'f8665f5085490c2184eebbc95bbc6c371190fc14';

/// See also [FolderController].
@ProviderFor(FolderController)
final folderControllerProvider =
    AutoDisposeAsyncNotifierProvider<FolderController, void>.internal(
  FolderController.new,
  name: r'folderControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$folderControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FolderController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
