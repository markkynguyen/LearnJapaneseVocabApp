import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/connectivity/cloud_connectivity.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/core/router/app_router.dart';
import 'package:jvocab/core/router/app_routes.dart';
import 'package:jvocab/features/auth/presentation/providers/auth_provider.dart';
import 'package:jvocab/features/folders/presentation/providers/folder_provider.dart';
import 'package:jvocab/features/home/presentation/providers/home_provider.dart';
import 'package:jvocab/features/home/presentation/widgets/home_vocab_search.dart';
import 'package:jvocab/features/kanji/data/kanji_repository.dart';
import 'package:jvocab/features/kanji/data/kanji_stroke_service.dart';
import 'package:jvocab/features/kanji/domain/kanji_models.dart';
import 'package:jvocab/features/kanji/presentation/kanji_home_screen.dart';
import 'package:jvocab/features/kanji/presentation/providers/kanji_providers.dart';
import 'package:jvocab/features/kanji/presentation/widgets/kanji_detail_dialog.dart';
import 'package:jvocab/features/settings/presentation/providers/settings_provider.dart';
import 'package:jvocab/features/vocab/presentation/flashcard_screen.dart';
import 'package:jvocab/features/vocab/presentation/providers/flashcard_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fixtures.dart';
import 'kanji_data_test.dart' show FakeKanjiStore;

List<Override> overrides(FakeKanjiStore store) => [
      supabaseClientProvider.overrideWith((ref) {
        final client = SupabaseClient(
          'https://example.supabase.co',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        ref.onDispose(client.dispose);
        return client;
      }),
      kanjiRepositoryProvider.overrideWithValue(KanjiRepository(store, 'test')),
      currentSessionProvider.overrideWith((ref) => null),
      kanjiDetailProvider.overrideWith(
        (ref, char) async =>
            char == '𠮷' ? null : Kanji.fromJson(kanjiJson(char)),
      ),
      kanjiStrokesProvider
          .overrideWith((ref, char) async => StrokeDocument.parse(sampleSvg)),
      kanjiComponentsProvider.overrideWith(
        (ref, id) async => [
          KanjiComponent(
            form: '亻',
            radical: Radical.fromJson(radicalJson()),
            sortOrder: 0,
          ),
        ],
      ),
      radicalKanjiIdsProvider
          .overrideWith((ref, id) async => {'休'.runes.single}),
      appSettingsProvider.overrideWith((ref) async => const AppSettings()),
    ];

Widget app(
  Widget child,
  FakeKanjiStore store, {
  List<Override> extra = const [],
  double textScale = 1,
}) =>
    ProviderScope(
      overrides: [...overrides(store), ...extra],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: child,
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
      'first visit does not recalculate, explicit button refresh populates grid',
      (tester) async {
    final store = FakeKanjiStore()..data = snapshotJson(empty: true);
    await tester.pumpWidget(app(const KanjiHomeScreen(), store));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có thống kê'), findsOneWidget);
    expect(store.recalculations, 0);
    store.data = snapshotJson();
    await tester.tap(find.text('Cập nhật thống kê'));
    await tester.pumpAndSettle();
    expect(store.recalculations, 1);
    expect(find.text('休'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.textContaining('chưa được hỗ trợ'), findsOneWidget);
    await tester.tap(find.text('Bộ thủ'));
    await tester.pumpAndSettle();
    expect(find.text('Nhân'), findsOneWidget);
  });
  testWidgets(
      'old snapshot remains accessible, small viewport and large text do not overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = FakeKanjiStore();
    await tester
        .pumpWidget(app(const KanjiHomeScreen(), store, textScale: 1.8));
    await tester.pumpAndSettle();
    expect(find.textContaining('2020'), findsOneWidget);
    expect(store.recalculations, 0);
    await tester.drag(find.byType(NestedScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('read errors expose retry; failed manual refresh leaves grid',
      (tester) async {
    final store = FakeKanjiStore()..error = StateError('unavailable');
    await tester.pumpWidget(app(const KanjiHomeScreen(), store));
    await tester.pumpAndSettle();
    expect(find.text('Không tải được thống kê.'), findsOneWidget);
    store.error = null;
    await tester.tap(find.text('Tải lại'));
    await tester.pumpAndSettle();
    store.error = StateError('unavailable');
    await tester.tap(find.text('Cập nhật thống kê'));
    await tester.pumpAndSettle();
    expect(find.text('休'), findsOneWidget);
    expect(find.textContaining('Chưa cập nhật được'), findsOneWidget);
  });
  testWidgets('detail pagination supports unknown characters and empty input',
      (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(body: KanjiDetailDialog(characters: ['先', '生', '𠮷'])),
        FakeKanjiStore(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1/3'), findsOneWidget);
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(find.text('生'), findsOneWidget);
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Chữ này chưa có'), findsOneWidget);
    await tester.tap(find.text('Trước'));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.pumpWidget(
      app(
        const Scaffold(body: KanjiDetailDialog(characters: [])),
        FakeKanjiStore(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('không có ký tự Hán tự'), findsOneWidget);
  });
  testWidgets('component navigation uses one dialog and returns to source',
      (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(body: KanjiDetailDialog(characters: ['休'])),
        FakeKanjiStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ActionChip, '亻 Nhân'));
    await tester.tap(find.widgetWithText(ActionChip, '亻 Nhân'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết bộ thủ'), findsOneWidget);
    expect(find.byType(Dialog), findsOneWidget);
    await tester.ensureVisible(find.widgetWithText(ActionChip, '休 · 12'));
    await tester.tap(find.widgetWithText(ActionChip, '休 · 12'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết bộ thủ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('four destinations preserve routes and selected indices',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        ...overrides(FakeKanjiStore()),
        routerGuardEnabledProvider.overrideWithValue(false),
        hasNetworkProvider.overrideWith((ref) => Stream.value(true)),
        foldersProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider)..go(AppRoutes.kanji);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NavigationBar>(find.byType(NavigationBar))
          .destinations
          .length,
      4,
    );
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    await tester.tap(find.text('Thư viện'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    router.go(AppRoutes.settings);
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
  });
  testWidgets('flashcard analysis opens current word without advancing deck',
      (tester) async {
    await tester.pumpWidget(
      app(
        const FlashcardScreen(folderId: 'folder'),
        FakeKanjiStore(),
        extra: [
          flashcardVocabularyProvider('folder')
              .overrideWith((ref) async => [vocab()]),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Phân tích Hán tự'));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
    await tester.tap(find.byTooltip('Đóng phân tích'));
    await tester.pumpAndSettle();
    expect(find.text('1/1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final emptyKanji in <String?>[null, '', '  ']) {
    testWidgets('flashcard hides analysis for empty Kanji: $emptyKanji',
        (tester) async {
      await tester.pumpWidget(
        app(
          const FlashcardScreen(folderId: 'folder'),
          FakeKanjiStore(),
          extra: [
            flashcardVocabularyProvider('folder').overrideWith(
              (ref) async => [vocab(kanji: emptyKanji)],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Phân tích Hán tự'), findsNothing);
    });
  }
  testWidgets('offline screen can navigate to saved Kanji', (tester) async {
    final container = ProviderContainer(
      overrides: [
        ...overrides(FakeKanjiStore()),
        routerGuardEnabledProvider.overrideWithValue(false),
        hasNetworkProvider.overrideWith((ref) => Stream.value(false)),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem Hán tự đã lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(KanjiHomeScreen), findsOneWidget);
    expect(find.text('休'), findsOneWidget);
  });
  testWidgets('home search exposes reusable analysis action', (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(body: HomeVocabSearch()),
        FakeKanjiStore(),
        extra: [
          homeVocabSuggestionsProvider('sensei').overrideWith(
            (ref) async => [
              VocabSearchResult(
                item: vocab(),
                folder: const Folder(
                  id: 'folder',
                  name: 'Từ vựng',
                  description: null,
                  color: '#6366F1',
                  createdAt: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    await tester.enterText(find.byType(TextField), 'sensei');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('先生'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Phân tích Hán tự'));
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
  });
  testWidgets(
    'captures readable light/dark UI for visual QA',
    (tester) async {
      final japanese = FontLoader('KleeOne')
        ..addFont(rootBundle.load('assets/fonts/KleeOne-Regular.ttf'));
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      final latin = FontLoader('QaLatin')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),
            ),
          ),
        );
      await japanese.load();
      await latin.load();
      await icons.load();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final brightness in Brightness.values) {
        final key = GlobalKey();
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides(FakeKanjiStore()),
            child: MaterialApp(
              theme: ThemeData(
                brightness: brightness,
                fontFamily: 'QaLatin',
                colorSchemeSeed: const Color(0xFF6366F1),
              ),
              home: RepaintBoundary(key: key, child: const KanjiHomeScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await capture(tester, key, 'home_${brightness.name}');
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides(FakeKanjiStore()),
            child: MaterialApp(
              theme: ThemeData(
                brightness: brightness,
                fontFamily: 'QaLatin',
                colorSchemeSeed: const Color(0xFF6366F1),
              ),
              home: RepaintBoundary(
                key: key,
                child: const Scaffold(
                  body: KanjiDetailDialog(characters: ['休', '先']),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await capture(tester, key, 'detail_${brightness.name}');
      }
    },
    skip: !const bool.fromEnvironment('KANJI_CAPTURE'),
  );
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/kanji_qa');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

VocabWithProgress vocab({String? kanji = '先生'}) => VocabWithProgress(
      vocab: VocabularyEntry(
        id: 'v1',
        folderId: 'folder',
        kanji: kanji,
        kana: 'せんせい',
        romaji: 'sensei',
        meaning: 'Giáo viên',
        isFavorite: false,
        createdAt: 0,
      ),
      progress: const SrsProgressEntry(
        vocabId: 'v1',
        level: 1,
        intervalDays: 1,
        nextReviewAt: 0,
        correctCount: 0,
        wrongCount: 0,
      ),
    );
