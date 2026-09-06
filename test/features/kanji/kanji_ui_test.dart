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
import 'package:jvocab/features/kanji/domain/kanji_vocabulary_readings.dart';
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
      kanjiStrokesProvider.overrideWith(
        (ref, char) async =>
            StrokeDocument.parse(sampleSvg, kanjivgCommit: 'test'),
      ),
      kanjiOccurrencesProvider.overrideWith(
        (ref, id) async =>
            [KanjiComponentOccurrence.fromJson(occurrenceJson())],
      ),
      kanjiComponentsProvider.overrideWith(
        (ref, id) async => [
          KanjiComponent(
            form: '亻',
            radical: Radical.fromJson(radicalJson()),
            sortOrder: 0,
          ),
        ],
      ),
      radicalKanjiIdsProvider.overrideWith(
        (ref, key) async =>
            key.form == '亻' ? {'休'.runes.single} : {'先'.runes.single},
      ),
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
    expect(find.text('Tổng quan thư viện'), findsNothing);
    expect(find.textContaining('từ đã quét'), findsNothing);
    expect(find.textContaining('Dữ liệu chỉ thay đổi'), findsNothing);
    await tester.tap(find.widgetWithText(Tab, 'Bộ thủ'));
    await tester.pumpAndSettle();
    expect(find.text('Nhân'), findsNWidgets(4));
  });
  testWidgets('tab bar stays pinned while the grid scrolls', (tester) async {
    final data = snapshotJson();
    data['kanji'] = List.generate(40, (_) => kanjiJson('休'));
    final store = FakeKanjiStore()..data = data;

    await tester.pumpWidget(app(const KanjiHomeScreen(), store));
    await tester.pumpAndSettle();

    final header = tester.widget<SliverPersistentHeader>(
      find.byType(SliverPersistentHeader),
    );
    expect(header.pinned, isTrue);

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final tabRect = tester.getRect(find.widgetWithText(Tab, 'Hán tự'));
    final appBarRect = tester.getRect(find.byType(AppBar));
    expect(tabRect.top, greaterThanOrEqualTo(appBarRect.bottom - 1));
  });
  testWidgets(
      'radical forms have separate cards, details, related Kanji and history',
      (tester) async {
    await tester.pumpWidget(app(const KanjiHomeScreen(), FakeKanjiStore()));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Bộ thủ'));
    await tester.pumpAndSettle();

    expect(find.text('Nhân'), findsNWidgets(4));
    expect(find.text('人'), findsOneWidget);
    expect(find.text('亻'), findsOneWidget);
    expect(find.text('𠆢'), findsOneWidget);
    expect(find.text('入'), findsOneWidget);
    expect(
      find.bySemanticsLabel('人, Nhân, dạng gốc, 8 lần xuất hiện'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('亻, Nhân, biến thể, 12 lần xuất hiện'),
      findsOneWidget,
    );

    await tester.tap(find.text('亻'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết bộ thủ'), findsOneWidget);
    expect(
      find.text('12 lần xuất hiện trong bản thống kê gần nhất.'),
      findsOneWidget,
    );
    expect(find.text('Dạng gốc'), findsOneWidget);
    expect(find.text('Các biến thể'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Dạng gốc')).style?.fontSize,
      20,
    );
    expect(
      tester.widget<Text>(find.text('Các biến thể')).style?.fontSize,
      20,
    );
    expect(find.widgetWithText(ActionChip, '休 · 12'), findsOneWidget);

    final originalBox = find.byKey(const ValueKey('radical-form:9:人'));
    await tester.ensureVisible(originalBox);
    await tester.tap(originalBox);
    await tester.pumpAndSettle();
    expect(
      find.text('8 lần xuất hiện trong bản thống kê gần nhất.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ActionChip, '先 · 8'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '休 · 12'), findsNothing);

    await tester.tap(find.byTooltip('Quay lại'));
    await tester.pumpAndSettle();
    expect(
      find.text('12 lần xuất hiện trong bản thống kê gần nhất.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(ActionChip, '休 · 12'), findsOneWidget);
  });
  testWidgets('radical detail hides form navigation when there are no variants',
      (tester) async {
    const radical = Radical(
      id: 75,
      character: '木',
      nameVi: 'Mộc',
      meaningVi: 'Cây',
      strokeCount: 4,
      count: 2,
    );
    await tester.pumpWidget(
      app(
        const Scaffold(
          body: RadicalDetailDialog(
            radicalForm: RadicalForm(
              radical: radical,
              form: '木',
              count: 2,
              familyCount: 2,
              isOriginal: true,
              formOrder: 0,
            ),
          ),
        ),
        FakeKanjiStore(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mộc'), findsOneWidget);
    expect(find.text('Dạng gốc'), findsNothing);
    expect(find.text('Các biến thể'), findsNothing);
    expect(find.byKey(const ValueKey('radical-form:75:木')), findsNothing);
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
    expect(find.text('SINH'), findsOneWidget);
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
  testWidgets('Kanji detail follows the requested visual hierarchy',
      (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(body: KanjiDetailDialog(characters: ['休'])),
        FakeKanjiStore(),
        extra: [
          kanjiVocabularyGroupsProvider.overrideWith(
            (ref, char) async => const KanjiVocabularyGroups(
              onyomi: [],
              kunyomi: [],
              unknown: [],
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lớp 1'), findsNothing);
    expect(find.text('6 nét'), findsNothing);
    expect(find.text('Bản dịch đang chờ duyệt.'), findsNothing);
    expect(find.text('Thành phần theo thứ tự viết'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data == '休' &&
            widget.style?.fontSize == 76,
      ),
      findsNothing,
    );

    final widgets = tester.allWidgets.toList();
    final orderedWidgets = [
      tester.widget(find.text('Thứ tự nét')),
      tester.widget<SegmentedButton<bool>>(
        find.byType(SegmentedButton<bool>),
      ),
      tester.widget(find.text('Nét 0/6')),
      tester.widget(find.text('HƯU')),
      tester.widget(find.text('Thành phần')),
      tester.widget(find.text('Nghĩa tiếng Việt')),
      tester.widget(find.text('Âm On (0)')),
      tester.widget(find.text('Âm Kun (0)')),
    ];
    for (var index = 1; index < orderedWidgets.length; index++) {
      expect(
        widgets.indexOf(orderedWidgets[index - 1]),
        lessThan(widgets.indexOf(orderedWidgets[index])),
      );
    }

    expect(
      tester.getCenter(find.text('HƯU')).dx,
      closeTo(tester.getCenter(find.byType(Dialog)).dx, 0.01),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('component:g1'))).dx,
      closeTo(tester.getTopLeft(find.text('Thành phần')).dx, 0.01),
    );
    for (final sectionTitle in [
      'Thứ tự nét',
      'Thành phần',
      'Nghĩa tiếng Việt',
      'Âm On (0)',
      'Âm Kun (0)',
    ]) {
      expect(
        tester.widget<Text>(find.text(sectionTitle)).style?.fontSize,
        20,
      );
    }
    expect(
      tester.widget<Text>(find.text('Nghỉ ngơi')).style?.fontSize,
      17,
    );
  });
  testWidgets('component selects strokes without opening radical details',
      (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(body: KanjiDetailDialog(characters: ['休'])),
        FakeKanjiStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, '亻 Nhân'));
    await tester.tap(find.widgetWithText(ChoiceChip, '亻 Nhân'));
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết bộ thủ'), findsNothing);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Nét 0/6'), findsOneWidget);
    await tester.tap(find.text('Bỏ chọn'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Bỏ chọn'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('pagination resets selection even for repeated characters',
      (tester) async {
    await tester.pumpWidget(
      app(
        const Scaffold(body: KanjiDetailDialog(characters: ['休', '休'])),
        FakeKanjiStore(),
      ),
    );
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(ChoiceChip, '亻 Nhân');
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('Bỏ chọn'), findsOneWidget);
    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    expect(find.text('2/2'), findsOneWidget);
    expect(find.text('Bỏ chọn'), findsNothing);
    expect(find.text('Nét 0/6'), findsOneWidget);
    expect(tester.widget<ChoiceChip>(chip).selected, isFalse);
  });
  testWidgets(
      'reading vocabulary is last, nested, collapsed and shows only requested fields',
      (tester) async {
    final groups = KanjiVocabularyGroups(
      onyomi: [
        KanjiVocabularyReadingGroup(
          type: KanjiReadingType.on,
          reading: 'キュウ',
          vocabulary: [
            _readingVocab(
              id: 'on',
              kanji: '休学',
              kana: 'きゅうがく',
              romaji: 'kyuugaku',
              meaning: 'tạm nghỉ học',
            ),
          ],
        ),
      ],
      kunyomi: [
        const KanjiVocabularyReadingGroup(
          type: KanjiReadingType.kun,
          reading: 'やす.む',
          vocabulary: [],
        ),
      ],
      unknown: [
        _readingVocab(
          id: 'unknown',
          kanji: '休日',
          kana: 'きゅうじつ',
          romaji: 'kyuujitsu',
          meaning: 'ngày nghỉ',
        ),
      ],
    );
    await tester.pumpWidget(
      app(
        const Scaffold(body: KanjiDetailDialog(characters: ['休'])),
        FakeKanjiStore(),
        extra: [
          kanjiVocabularyGroupsProvider.overrideWith(
            (ref, char) async => groups,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Âm On (1)'), findsOneWidget);
    expect(find.text('Âm Kun (0)'), findsOneWidget);
    expect(find.text('Chưa xác định (1)'), findsOneWidget);
    expect(find.text('キュウ (1)'), findsNothing);
    final widgets = tester.allWidgets.toList();
    expect(
      widgets.indexOf(tester.widget(find.text('Thứ tự nét'))),
      lessThan(widgets.indexOf(tester.widget(find.text('Âm On (1)')))),
    );

    await tester.ensureVisible(find.text('Âm On (1)'));
    await tester.tap(find.text('Âm On (1)'));
    await tester.pumpAndSettle();
    expect(find.text('キュウ (1)'), findsOneWidget);
    expect(find.text('休学'), findsNothing);
    expect(find.text('やす.む (0)'), findsNothing);

    await tester.tap(find.text('キュウ (1)'));
    await tester.pumpAndSettle();
    expect(find.text('休学'), findsOneWidget);
    expect(find.text('きゅうがく'), findsOneWidget);
    expect(find.text('tạm nghỉ học'), findsOneWidget);
    expect(find.text('kyuugaku'), findsNothing);
    final readingLeft = tester.getTopLeft(find.text('キュウ (1)')).dx;
    final vocabularyLeft = tester.getTopLeft(find.text('休学')).dx;
    expect(vocabularyLeft, greaterThanOrEqualTo(readingLeft - 2));
    expect(vocabularyLeft, lessThan(readingLeft + 24));

    await tester.ensureVisible(find.text('Âm Kun (0)'));
    await tester.tap(find.text('Âm Kun (0)'));
    await tester.pumpAndSettle();
    expect(find.text('やす.む (0)'), findsOneWidget);
    await tester.tap(find.text('やす.む (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có từ vựng trong Thư viện.'), findsOneWidget);
  });
  testWidgets('changing Kanji resets reading expansion state', (tester) async {
    final group = KanjiVocabularyGroups(
      onyomi: [
        KanjiVocabularyReadingGroup(
          type: KanjiReadingType.on,
          reading: 'キュウ',
          vocabulary: [
            _readingVocab(
              id: 'word',
              kanji: '休学',
              kana: 'きゅうがく',
              romaji: 'kyuugaku',
              meaning: 'tạm nghỉ học',
            ),
          ],
        ),
      ],
      kunyomi: const [],
      unknown: const [],
    );
    await tester.pumpWidget(
      app(
        const Scaffold(body: KanjiDetailDialog(characters: ['休', '先'])),
        FakeKanjiStore(),
        extra: [
          kanjiVocabularyGroupsProvider.overrideWith(
            (ref, char) async => group,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Âm On (1)'));
    await tester.tap(find.text('Âm On (1)'));
    await tester.pumpAndSettle();
    expect(find.text('キュウ (1)'), findsOneWidget);

    await tester.tap(find.text('Tiếp'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Âm On (1)'));
    expect(find.text('キュウ (1)'), findsNothing);
  });
  testWidgets('reading vocabulary error is local and retryable',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      app(
        const Scaffold(body: KanjiDetailDialog(characters: ['休'])),
        FakeKanjiStore(),
        extra: [
          kanjiVocabularyGroupsProvider.overrideWith((ref, char) async {
            attempts++;
            if (attempts == 1) throw StateError('offline');
            return const KanjiVocabularyGroups(
              onyomi: [
                KanjiVocabularyReadingGroup(
                  type: KanjiReadingType.on,
                  reading: 'キュウ',
                  vocabulary: [],
                ),
              ],
              kunyomi: [],
              unknown: [],
            );
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HƯU'), findsOneWidget);
    expect(find.text('Không tải được từ vựng trong Thư viện.'), findsOneWidget);

    await tester.ensureVisible(find.text('Thử lại'));
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Âm On (0)'), findsOneWidget);
    expect(attempts, 2);
  });
  testWidgets(
      'stale snapshot warns and blocks related Kanji without recalculation',
      (tester) async {
    final store = FakeKanjiStore();
    (store.data['overview'] as Map)['component_version'] = 1;
    await tester.pumpWidget(app(const KanjiHomeScreen(), store));
    await tester.pumpAndSettle();
    expect(find.textContaining('Quy tắc phân tích'), findsOneWidget);
    expect(find.textContaining('2020'), findsOneWidget);
    await tester.tap(find.widgetWithText(Tab, 'Bộ thủ'));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(NestedScrollView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhân').first);
    await tester.pumpAndSettle();
    expect(find.text('Chi tiết bộ thủ'), findsOneWidget);
    expect(find.textContaining('để xem Kanji liên quan'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '休 · 12'), findsNothing);
    expect(store.recalculations, 0);
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
      2,
    );
    await tester.tap(find.text('Thư viện'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
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
        await tester.tap(find.widgetWithText(Tab, 'Bộ thủ'));
        await tester.pumpAndSettle();
        await capture(tester, key, 'radical_home_${brightness.name}');
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
                child: Scaffold(
                  body: RadicalDetailDialog(
                    radicalForm: RadicalForm.fromJson(
                      radicalFormJson(
                        form: '亻',
                        count: 12,
                        isOriginal: false,
                        formOrder: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await capture(tester, key, 'radical_detail_${brightness.name}');
        final detailStore = FakeKanjiStore()
          ..vocabulary = [
            _readingVocab(
              id: 'capture-on',
              kanji: '休',
              kana: 'きゅう',
              romaji: 'kyuu',
              meaning: 'sự nghỉ ngơi',
            ),
            _readingVocab(
              id: 'capture-kun',
              kanji: '休む',
              kana: 'やすむ',
              romaji: 'yasumu',
              meaning: 'nghỉ',
            ),
          ];
        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides(detailStore),
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
        await tester.ensureVisible(find.text('Âm On (1)'));
        await tester.pumpAndSettle();
        await capture(tester, key, 'detail_readings_${brightness.name}');
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

VocabularyEntry _readingVocab({
  required String id,
  required String kanji,
  required String kana,
  required String romaji,
  required String meaning,
}) =>
    VocabularyEntry(
      id: id,
      folderId: 'folder',
      kanji: kanji,
      kana: kana,
      romaji: romaji,
      meaning: meaning,
      isFavorite: false,
      createdAt: 0,
    );
