// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appSettingsHash() => r'7b1643fc0ef1bb28485613f891c1b3b1b8d94aea';

/// See also [appSettings].
@ProviderFor(appSettings)
final appSettingsProvider = AutoDisposeStreamProvider<AppSettings>.internal(
  appSettings,
  name: r'appSettingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppSettingsRef = AutoDisposeStreamProviderRef<AppSettings>;
String _$themeModeHash() => r'1e2defc2bde04c484a42d0a34b47ac4cbc6648fc';

/// See also [themeMode].
@ProviderFor(themeMode)
final themeModeProvider = AutoDisposeProvider<ThemeMode>.internal(
  themeMode,
  name: r'themeModeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$themeModeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ThemeModeRef = AutoDisposeProviderRef<ThemeMode>;
String _$settingsControllerHash() =>
    r'6411ae1541375cd97b321e05e1e5c4efe558c44d';

/// See also [SettingsController].
@ProviderFor(SettingsController)
final settingsControllerProvider =
    AutoDisposeAsyncNotifierProvider<SettingsController, void>.internal(
  SettingsController.new,
  name: r'settingsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SettingsController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
