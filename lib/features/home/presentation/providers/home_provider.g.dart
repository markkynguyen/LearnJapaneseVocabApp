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
String _$folderSummariesHash() => r'af12dd5cfc4744e7100027da86a8e8eebd54a626';

/// See also [folderSummaries].
@ProviderFor(folderSummaries)
final folderSummariesProvider =
    AutoDisposeStreamProvider<List<FolderSummary>>.internal(
  folderSummaries,
  name: r'folderSummariesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$folderSummariesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FolderSummariesRef = AutoDisposeStreamProviderRef<List<FolderSummary>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
