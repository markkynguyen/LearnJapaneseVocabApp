// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$vocabularyRepositoryHash() =>
    r'f9367c072bc6e9979a0187286fdd237c9dfa10d5';

/// See also [vocabularyRepository].
@ProviderFor(vocabularyRepository)
final vocabularyRepositoryProvider =
    AutoDisposeProvider<VocabularyRepository>.internal(
  vocabularyRepository,
  name: r'vocabularyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$vocabularyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef VocabularyRepositoryRef = AutoDisposeProviderRef<VocabularyRepository>;
String _$vocabFormItemHash() => r'85ab63a5aca855b7315683510c1793eddc4b7c0c';

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

/// See also [vocabFormItem].
@ProviderFor(vocabFormItem)
const vocabFormItemProvider = VocabFormItemFamily();

/// See also [vocabFormItem].
class VocabFormItemFamily extends Family<AsyncValue<VocabWithProgress?>> {
  /// See also [vocabFormItem].
  const VocabFormItemFamily();

  /// See also [vocabFormItem].
  VocabFormItemProvider call(
    String vocabId,
  ) {
    return VocabFormItemProvider(
      vocabId,
    );
  }

  @override
  VocabFormItemProvider getProviderOverride(
    covariant VocabFormItemProvider provider,
  ) {
    return call(
      provider.vocabId,
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
  String? get name => r'vocabFormItemProvider';
}

/// See also [vocabFormItem].
class VocabFormItemProvider
    extends AutoDisposeFutureProvider<VocabWithProgress?> {
  /// See also [vocabFormItem].
  VocabFormItemProvider(
    String vocabId,
  ) : this._internal(
          (ref) => vocabFormItem(
            ref as VocabFormItemRef,
            vocabId,
          ),
          from: vocabFormItemProvider,
          name: r'vocabFormItemProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$vocabFormItemHash,
          dependencies: VocabFormItemFamily._dependencies,
          allTransitiveDependencies:
              VocabFormItemFamily._allTransitiveDependencies,
          vocabId: vocabId,
        );

  VocabFormItemProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.vocabId,
  }) : super.internal();

  final String vocabId;

  @override
  Override overrideWith(
    FutureOr<VocabWithProgress?> Function(VocabFormItemRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: VocabFormItemProvider._internal(
        (ref) => create(ref as VocabFormItemRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        vocabId: vocabId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<VocabWithProgress?> createElement() {
    return _VocabFormItemProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is VocabFormItemProvider && other.vocabId == vocabId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, vocabId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin VocabFormItemRef on AutoDisposeFutureProviderRef<VocabWithProgress?> {
  /// The parameter `vocabId` of this provider.
  String get vocabId;
}

class _VocabFormItemProviderElement
    extends AutoDisposeFutureProviderElement<VocabWithProgress?>
    with VocabFormItemRef {
  _VocabFormItemProviderElement(super.provider);

  @override
  String get vocabId => (origin as VocabFormItemProvider).vocabId;
}

String _$vocabFormControllerHash() =>
    r'7eba132aa38a11fcde4402615a1b9bbd295d59a9';

/// See also [VocabFormController].
@ProviderFor(VocabFormController)
final vocabFormControllerProvider =
    AutoDisposeAsyncNotifierProvider<VocabFormController, void>.internal(
  VocabFormController.new,
  name: r'vocabFormControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$vocabFormControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VocabFormController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
