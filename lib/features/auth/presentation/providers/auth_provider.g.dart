// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$oauthLauncherHash() => r'44821ac450156da14d8e2d2fe19ca91292ce3b1a';

/// See also [oauthLauncher].
@ProviderFor(oauthLauncher)
final oauthLauncherProvider = AutoDisposeProvider<OAuthLauncher>.internal(
  oauthLauncher,
  name: r'oauthLauncherProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$oauthLauncherHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef OauthLauncherRef = AutoDisposeProviderRef<OAuthLauncher>;
String _$authStateHash() => r'998fcc9038cafdc19cb355cd5e0f11b26a48521d';

/// See also [authState].
@ProviderFor(authState)
final authStateProvider = AutoDisposeStreamProvider<AuthState>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AuthStateRef = AutoDisposeStreamProviderRef<AuthState>;
String _$currentSessionHash() => r'09759fafe80cea4198824497bb1f4c71a436c0e3';

/// See also [currentSession].
@ProviderFor(currentSession)
final currentSessionProvider = AutoDisposeProvider<Session?>.internal(
  currentSession,
  name: r'currentSessionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentSessionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentSessionRef = AutoDisposeProviderRef<Session?>;
String _$authControllerHash() => r'13d0626ae24dd5be7372c86a4d8eab533cbf9a37';

/// See also [AuthController].
@ProviderFor(AuthController)
final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>.internal(
  AuthController.new,
  name: r'authControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthController = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
