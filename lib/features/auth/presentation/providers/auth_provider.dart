import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/cloud/cloud_store.dart';

part 'auth_provider.g.dart';

typedef OAuthLauncher = Future<bool> Function(
  OAuthProvider provider, {
  required String redirectTo,
});

String resolveAuthRedirectUrl({required bool isWeb, Uri? baseUri}) => isWeb
    ? (baseUri ?? Uri.base).resolve('/auth-callback').toString()
    : 'nanaapp://auth-callback';

String get _authRedirectUrl => resolveAuthRedirectUrl(isWeb: kIsWeb);

@riverpod
OAuthLauncher oauthLauncher(OauthLauncherRef ref) {
  final auth = ref.watch(supabaseClientProvider).auth;
  return (provider, {required redirectTo}) => auth.signInWithOAuth(
        provider,
        redirectTo: redirectTo,
      );
}

@riverpod
Stream<AuthState> authState(AuthStateRef ref) =>
    ref.watch(supabaseClientProvider).auth.onAuthStateChange;

@riverpod
Session? currentSession(CurrentSessionRef ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
}

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(supabaseClientProvider).auth.signInWithPassword(
            email: email.trim(),
            password: password,
          );
      await ref.read(cloudStoreProvider).bootstrapUser();
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final opened = await ref.read(oauthLauncherProvider)(
        OAuthProvider.google,
        redirectTo: _authRedirectUrl,
      );
      if (!opened) {
        throw const AuthException(
          'Không thể mở trình duyệt để đăng nhập bằng Google.',
        );
      }
    });
  }

  Future<bool> signUp(String email, String password) async {
    state = const AsyncLoading();
    var confirmationRequired = true;
    state = await AsyncValue.guard(() async {
      final response = await ref.read(supabaseClientProvider).auth.signUp(
            email: email.trim(),
            password: password,
            emailRedirectTo: _authRedirectUrl,
          );
      confirmationRequired = response.session == null;
      if (!confirmationRequired) {
        await ref.read(cloudStoreProvider).bootstrapUser();
      }
    });
    return !state.hasError && confirmationRequired;
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(supabaseClientProvider).auth.resetPasswordForEmail(
            email.trim(),
            redirectTo: _authRedirectUrl,
          ),
    );
  }

  Future<void> updatePassword(String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(supabaseClientProvider)
          .auth
          .updateUser(UserAttributes(password: password)),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(supabaseClientProvider).auth.signOut(),
    );
  }
}
