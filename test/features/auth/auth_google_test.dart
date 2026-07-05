import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/features/auth/presentation/auth_screen.dart';
import 'package:jvocab/features/auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('OAuth redirect uses the web origin and native custom scheme', () {
    expect(
      resolveAuthRedirectUrl(
        isWeb: true,
        baseUri: Uri.parse('https://nana.example/library?tab=1'),
      ),
      'https://nana.example/auth-callback',
    );
    expect(
      resolveAuthRedirectUrl(isWeb: false),
      'nanaapp://auth-callback',
    );
  });

  test('Google sign-in launches the right provider and native redirect',
      () async {
    OAuthProvider? launchedProvider;
    String? launchedRedirect;
    final container = ProviderContainer(
      overrides: [
        oauthLauncherProvider.overrideWithValue(
          (provider, {required redirectTo}) async {
            launchedProvider = provider;
            launchedRedirect = redirectTo;
            return true;
          },
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(authControllerProvider, (_, __) {});
    addTearDown(subscription.close);

    await container.read(authControllerProvider.notifier).signInWithGoogle();

    expect(launchedProvider, OAuthProvider.google);
    expect(launchedRedirect, 'nanaapp://auth-callback');
    expect(container.read(authControllerProvider).hasError, isFalse);
  });

  testWidgets('Google button is available for sign-in and registration',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          oauthLauncherProvider.overrideWithValue(
            (provider, {required redirectTo}) async => true,
          ),
        ],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('hoặc'), findsOneWidget);

    final registerToggle = find.text('Chưa có tài khoản? Đăng ký');
    await tester.ensureVisible(registerToggle);
    await tester.tap(registerToggle);
    await tester.pump();

    expect(find.text('Tiếp tục với Google'), findsOneWidget);
    expect(find.text('Tạo tài khoản Nana'), findsOneWidget);
  });

  testWidgets('Google button is disabled while the browser is opening',
      (tester) async {
    final launch = Completer<bool>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          oauthLauncherProvider.overrideWithValue(
            (provider, {required redirectTo}) => launch.future,
          ),
        ],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('google-auth-button')));
    await tester.pump();

    final loadingButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('google-auth-button')),
    );
    expect(loadingButton.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    launch.complete(true);
    await tester.pumpAndSettle();
    final readyButton = tester.widget<OutlinedButton>(
      find.byKey(const Key('google-auth-button')),
    );
    expect(readyButton.onPressed, isNotNull);
  });

  testWidgets('browser launch failure is shown as a friendly message',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          oauthLauncherProvider.overrideWithValue(
            (provider, {required redirectTo}) async => false,
          ),
        ],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );

    await tester.tap(find.byKey(const Key('google-auth-button')));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
        'Không thể mở trình duyệt để đăng nhập bằng Google.',
      ),
      findsOneWidget,
    );
  });

  test('common Google OAuth failures use friendly messages', () {
    expect(
      friendlyAuthError(const AuthException('Provider is not enabled')),
      contains('Đăng nhập Google chưa được bật'),
    );
    expect(
      friendlyAuthError(const AuthException('redirect URL mismatch')),
      contains('Đường dẫn quay lại ứng dụng chưa đúng'),
    );
    expect(
      friendlyAuthError(Exception('network connection failed')),
      contains('Hãy kiểm tra mạng'),
    );
  });
}
