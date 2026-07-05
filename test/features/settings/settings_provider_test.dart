import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/core/connectivity/cloud_connectivity.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/settings/presentation/providers/settings_provider.dart';
import 'package:jvocab/features/settings/presentation/settings_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('draft stays local until save and reloads after cloud confirmation',
      () async {
    final saveGate = Completer<void>();
    final store = _FakeCloudStore(saveGate: saveGate);
    final container = _containerFor(store);
    addTearDown(container.dispose);

    final original = await container.read(appSettingsProvider.future);
    final draft = original.copyWith(
      themeMode: darkThemeModeValue,
      sessionSize: 25,
    );

    expect(store.saveCallCount, 0);
    expect(original.themeMode, lightThemeModeValue);
    expect(original.sessionSize, 10);

    final update =
        container.read(settingsControllerProvider.notifier).saveSettings(draft);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(settingsControllerProvider).isLoading, isTrue);
    expect(store.saveCallCount, 1);

    saveGate.complete();
    expect(await update, isTrue);

    expect(container.read(settingsControllerProvider).hasError, isFalse);
    final refreshed = await container.read(appSettingsProvider.future);
    expect(refreshed.themeMode, darkThemeModeValue);
    expect(refreshed.sessionSize, 25);
  });

  testWidgets('settings controls stay local until the Save button is tapped',
      (tester) async {
    final store = _FakeCloudStore();
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudStoreProvider.overrideWithValue(store),
          supabaseClientProvider.overrideWithValue(client),
          deviceIdProvider.overrideWith((ref) async => 'test-device'),
          hasNetworkProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = find.ancestor(
      of: find.text('Lưu'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);

    await tester.tap(find.byTooltip('Tăng').first);
    await tester.pump();

    expect(store.saveCallCount, 0);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(store.saveCallCount, 1);
    expect(store.lastSavedSettings?.newWordSessionSize, 6);
    expect(find.text('Đã lưu cài đặt lên cloud.'), findsOneWidget);
  });

  testWidgets('leaving settings asks whether to save pending changes',
      (tester) async {
    final store = _FakeCloudStore();
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cloudStoreProvider.overrideWithValue(store),
          supabaseClientProvider.overrideWithValue(client),
          deviceIdProvider.overrideWith((ref) async => 'test-device'),
          hasNetworkProvider.overrideWith((ref) => Stream.value(true)),
        ],
        child: const _GuardedSettingsApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tăng').first);
    await tester.pump();
    GoRouter.of(tester.element(find.byType(SettingsScreen))).go('/other');
    await tester.pumpAndSettle();

    expect(find.text('Lưu thay đổi?'), findsOneWidget);
    expect(find.text('Không lưu'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    GoRouter.of(tester.element(find.byType(SettingsScreen))).go('/other');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Không lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Trang khác'), findsOneWidget);
    expect(store.saveCallCount, 0);
  });
}

class _GuardedSettingsApp extends ConsumerStatefulWidget {
  const _GuardedSettingsApp();

  @override
  ConsumerState<_GuardedSettingsApp> createState() =>
      _GuardedSettingsAppState();
}

class _GuardedSettingsAppState extends ConsumerState<_GuardedSettingsApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
          onExit: confirmPendingSettingsChanges,
        ),
        GoRoute(
          path: '/other',
          builder: (context, state) => const Scaffold(body: Text('Trang khác')),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        routerConfig: _router,
      );
}

ProviderContainer _containerFor(CloudStore store) => ProviderContainer(
      overrides: [
        cloudStoreProvider.overrideWithValue(store),
        deviceIdProvider.overrideWith((ref) async => 'test-device'),
      ],
    );

class _FakeCloudStore extends CloudStore {
  _FakeCloudStore({this.saveGate})
      : super(
          SupabaseClient(
            'https://example.supabase.co',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  final Completer<void>? saveGate;
  int saveCallCount = 0;
  AppSettings? lastSavedSettings;
  String _themeMode = lightThemeModeValue;
  int _sessionSize = 10;

  @override
  Future<AppSettings> getSettings(String deviceId) async => AppSettings(
        themeMode: _themeMode,
        sessionSize: _sessionSize,
      );

  @override
  Future<void> saveSettings(
    String deviceId,
    AppSettings settings,
  ) async {
    saveCallCount++;
    lastSavedSettings = settings;
    await saveGate?.future;
    _themeMode = settings.themeMode;
    _sessionSize = settings.sessionSize;
  }
}
