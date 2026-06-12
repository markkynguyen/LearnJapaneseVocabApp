// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flashcard_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$flashcardVocabularyHash() =>
    r'0053bd454681d6a5c808a4700fce16d8d707f1b4';

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

/// See also [flashcardVocabulary].
@ProviderFor(flashcardVocabulary)
const flashcardVocabularyProvider = FlashcardVocabularyFamily();

/// See also [flashcardVocabulary].
class FlashcardVocabularyFamily
    extends Family<AsyncValue<List<VocabWithProgress>>> {
  /// See also [flashcardVocabulary].
  const FlashcardVocabularyFamily();

  /// See also [flashcardVocabulary].
  FlashcardVocabularyProvider call(
    int folderId,
  ) {
    return FlashcardVocabularyProvider(
      folderId,
    );
  }

  @override
  FlashcardVocabularyProvider getProviderOverride(
    covariant FlashcardVocabularyProvider provider,
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
  String? get name => r'flashcardVocabularyProvider';
}

/// See also [flashcardVocabulary].
class FlashcardVocabularyProvider
    extends AutoDisposeStreamProvider<List<VocabWithProgress>> {
  /// See also [flashcardVocabulary].
  FlashcardVocabularyProvider(
    int folderId,
  ) : this._internal(
          (ref) => flashcardVocabulary(
            ref as FlashcardVocabularyRef,
            folderId,
          ),
          from: flashcardVocabularyProvider,
          name: r'flashcardVocabularyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$flashcardVocabularyHash,
          dependencies: FlashcardVocabularyFamily._dependencies,
          allTransitiveDependencies:
              FlashcardVocabularyFamily._allTransitiveDependencies,
          folderId: folderId,
        );

  FlashcardVocabularyProvider._internal(
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
    Stream<List<VocabWithProgress>> Function(FlashcardVocabularyRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: FlashcardVocabularyProvider._internal(
        (ref) => create(ref as FlashcardVocabularyRef),
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
    return _FlashcardVocabularyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FlashcardVocabularyProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FlashcardVocabularyRef
    on AutoDisposeStreamProviderRef<List<VocabWithProgress>> {
  /// The parameter `folderId` of this provider.
  int get folderId;
}

class _FlashcardVocabularyProviderElement
    extends AutoDisposeStreamProviderElement<List<VocabWithProgress>>
    with FlashcardVocabularyRef {
  _FlashcardVocabularyProviderElement(super.provider);

  @override
  int get folderId => (origin as FlashcardVocabularyProvider).folderId;
}

String _$flashcardDeckHash() => r'0e124ad58d4b222cc49d75d8c456362ac3a3f06f';

abstract class _$FlashcardDeck
    extends BuildlessAutoDisposeAsyncNotifier<FlashcardDeckState> {
  late final int folderId;

  FutureOr<FlashcardDeckState> build(
    int folderId,
  );
}

/// See also [FlashcardDeck].
@ProviderFor(FlashcardDeck)
const flashcardDeckProvider = FlashcardDeckFamily();

/// See also [FlashcardDeck].
class FlashcardDeckFamily extends Family<AsyncValue<FlashcardDeckState>> {
  /// See also [FlashcardDeck].
  const FlashcardDeckFamily();

  /// See also [FlashcardDeck].
  FlashcardDeckProvider call(
    int folderId,
  ) {
    return FlashcardDeckProvider(
      folderId,
    );
  }

  @override
  FlashcardDeckProvider getProviderOverride(
    covariant FlashcardDeckProvider provider,
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
  String? get name => r'flashcardDeckProvider';
}

/// See also [FlashcardDeck].
class FlashcardDeckProvider extends AutoDisposeAsyncNotifierProviderImpl<
    FlashcardDeck, FlashcardDeckState> {
  /// See also [FlashcardDeck].
  FlashcardDeckProvider(
    int folderId,
  ) : this._internal(
          () => FlashcardDeck()..folderId = folderId,
          from: flashcardDeckProvider,
          name: r'flashcardDeckProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$flashcardDeckHash,
          dependencies: FlashcardDeckFamily._dependencies,
          allTransitiveDependencies:
              FlashcardDeckFamily._allTransitiveDependencies,
          folderId: folderId,
        );

  FlashcardDeckProvider._internal(
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
  FutureOr<FlashcardDeckState> runNotifierBuild(
    covariant FlashcardDeck notifier,
  ) {
    return notifier.build(
      folderId,
    );
  }

  @override
  Override overrideWith(FlashcardDeck Function() create) {
    return ProviderOverride(
      origin: this,
      override: FlashcardDeckProvider._internal(
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
  AutoDisposeAsyncNotifierProviderElement<FlashcardDeck, FlashcardDeckState>
      createElement() {
    return _FlashcardDeckProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FlashcardDeckProvider && other.folderId == folderId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, folderId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FlashcardDeckRef
    on AutoDisposeAsyncNotifierProviderRef<FlashcardDeckState> {
  /// The parameter `folderId` of this provider.
  int get folderId;
}

class _FlashcardDeckProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<FlashcardDeck,
        FlashcardDeckState> with FlashcardDeckRef {
  _FlashcardDeckProviderElement(super.provider);

  @override
  int get folderId => (origin as FlashcardDeckProvider).folderId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
