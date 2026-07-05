import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/connectivity/offline_screen.dart';
import 'package:jvocab/features/auth/presentation/auth_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
    );
  });

  testWidgets('auth screen requires valid email and password', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pump();

    expect(find.text('Email không hợp lệ.'), findsOneWidget);
    expect(find.text('Mật khẩu cần ít nhất 8 ký tự.'), findsOneWidget);
  });

  testWidgets('offline screen exposes retry action', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(home: OfflineScreen(onRetry: () => retried = true)),
    );

    expect(find.text('Không có kết nối'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Thử lại'));
    expect(retried, isTrue);
  });
}
