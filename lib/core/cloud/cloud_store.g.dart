// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cloud_store.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supabaseClientHash() => r'a423e7187c202c89ed9ab6db50e56f0695ae703d';

/// See also [supabaseClient].
@ProviderFor(supabaseClient)
final supabaseClientProvider = Provider<SupabaseClient>.internal(
  supabaseClient,
  name: r'supabaseClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supabaseClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SupabaseClientRef = ProviderRef<SupabaseClient>;
String _$cloudStoreHash() => r'b97903d05136adb38d448bd771d1c79bdbbe1813';

/// See also [cloudStore].
@ProviderFor(cloudStore)
final cloudStoreProvider = Provider<CloudStore>.internal(
  cloudStore,
  name: r'cloudStoreProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$cloudStoreHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CloudStoreRef = ProviderRef<CloudStore>;
String _$cloudBootstrapHash() => r'3113fcb01d91671ff8990947930417d7fd7dd473';

/// See also [cloudBootstrap].
@ProviderFor(cloudBootstrap)
final cloudBootstrapProvider = AutoDisposeFutureProvider<void>.internal(
  cloudBootstrap,
  name: r'cloudBootstrapProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cloudBootstrapHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CloudBootstrapRef = AutoDisposeFutureProviderRef<void>;
String _$deviceIdHash() => r'3624864efab05bdc22d0e5e5ded3b6a2ce90fe1a';

/// See also [deviceId].
@ProviderFor(deviceId)
final deviceIdProvider = FutureProvider<String>.internal(
  deviceId,
  name: r'deviceIdProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$deviceIdHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef DeviceIdRef = FutureProviderRef<String>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
