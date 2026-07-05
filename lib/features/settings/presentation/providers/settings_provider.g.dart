// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appSettingsHash() => r'dd31e783cb40788fb0c8624e716987661b958bdf';

/// See also [appSettings].
@ProviderFor(appSettings)
final appSettingsProvider = AutoDisposeFutureProvider<AppSettings>.internal(
  appSettings,
  name: r'appSettingsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$appSettingsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AppSettingsRef = AutoDisposeFutureProviderRef<AppSettings>;
String _$themeModeHash() => r'dc3e4365ce28a611c810a387569ae7f242f07ef2';

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
String _$settingsDraftControllerHash() =>
    r'4541b4f40b3024bed4f7bd78a344acb5e7274110';

/// See also [SettingsDraftController].
@ProviderFor(SettingsDraftController)
final settingsDraftControllerProvider =
    NotifierProvider<SettingsDraftController, SettingsDraftState>.internal(
  SettingsDraftController.new,
  name: r'settingsDraftControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsDraftControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SettingsDraftController = Notifier<SettingsDraftState>;
String _$settingsControllerHash() =>
    r'5e33ed9b669687a89ff7d59c48e8892d49136c8d';

/// See also [SettingsController].
@ProviderFor(SettingsController)
final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, void>.internal(
  SettingsController.new,
  name: r'settingsControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$settingsControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SettingsController = AsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
