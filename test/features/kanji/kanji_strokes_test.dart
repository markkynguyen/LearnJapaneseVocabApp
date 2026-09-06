import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jvocab/features/kanji/data/kanji_stroke_service.dart';
import 'package:jvocab/features/kanji/domain/kanji_models.dart';
import 'package:jvocab/features/kanji/presentation/widgets/kanji_stroke_animator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('parses ordered paths only, rejects invalid SVG', () {
    expect(StrokeDocument.parse(sampleSvg).paths, hasLength(6));
    expect(
      () => StrokeDocument.parse('<html>error</html>'),
      throwsFormatException,
    );
    expect(
      () => StrokeDocument.parse(
        sampleSvg.replaceFirst('0 0 109 109', '0 0 0 0'),
      ),
      throwsFormatException,
    );
    final transformed = StrokeDocument.parse(
      sampleSvg.replaceFirst(
        '<g>',
        '<g transform="translate(1,1)"><script>bad()</script>',
      ),
    );
    expect(transformed.supportsAnimation, isFalse);
    expect(transformed.strokeCount, 6);
    expect(transformed.staticSvgAt(2), contains('translate(1,1)'));
    expect(transformed.staticSvgAt(2), isNot(contains('script')));
    expect('<path'.allMatches(transformed.staticSvgAt(2)).length, 6);
    expect(
      'stroke-opacity="0.15"'.allMatches(transformed.staticSvgAt(2)).length,
      4,
    );
    expect(transformed.strokeIds, ['s1', 's2', 's3', 's4', 's5', 's6']);
    final colored = transformed.staticSvgAt(0, highlighted: {'s2'});
    expect('stroke="#d32f2f"'.allMatches(colored).length, 1);
    expect(colored, isNot(contains('stroke-opacity="0.15"')));
    expect(
      transformed.staticSvgAt(0, strokeWidth: 6),
      contains('stroke-width="6.0"'),
    );
  });
  test(
      'pins URL, shares inflight fetch, persists across service restarts and repairs corruption',
      () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      expect(
        request.url.toString(),
        'https://cdn.jsdelivr.net/gh/KanjiVG/kanjivg@abc123/kanji/04f11.svg',
      );
      return http.Response(sampleSvg, 200);
    });
    final cache = PersistentStrokeCache();
    final service =
        KanjiStrokeService(client: client, cache: cache, version: 'abc123');
    await cache.write(service.cacheKey('休'), 'bad cache');
    final documents = await Future.wait([service.load('休'), service.load('休')]);
    expect(calls, 1);
    expect(documents.first, same(documents.last));
    await service.load('休');
    expect(calls, 1);
    final offline = KanjiStrokeService(
      client: MockClient((_) => throw http.ClientException('offline')),
      cache: cache,
      version: 'abc123',
    );
    expect((await offline.load('休')).paths, hasLength(6));
    await service.invalidate('休');
    await service.load('休');
    expect(
      calls,
      2,
      reason: 'explicit retry bypasses memory and persistent SVG',
    );
    expect(service.cacheKey('𠮟'), endsWith('.20b9f'));
    expect(() => service.cacheKey('../'), throwsFormatException);
  });
  test('failed request is retryable and never persisted', () async {
    var fail = true;
    final service = KanjiStrokeService(
      version: 'v1',
      cache: PersistentStrokeCache(),
      client: MockClient(
        (_) async =>
            http.Response(fail ? 'missing' : sampleSvg, fail ? 404 : 200),
      ),
    );
    await expectLater(service.load('休'), throwsStateError);
    fail = false;
    expect((await service.load('休')).paths.length, 6);
  });
  testWidgets('steps, playback, pause, replay, reduce motion and disposal',
      (tester) async {
    final document = StrokeDocument.parse(sampleSvg);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KanjiStrokeAnimator(document: document)),
      ),
    );
    expect(find.text('Nét 0/6'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Nét trước',
            ),
          )
          .onPressed,
      isNull,
    );
    KanjiStrokePainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<KanjiStrokePainter>()
        .single;
    expect(painter().progress, 6);
    await tester.tap(find.byTooltip('Nét tiếp'));
    await tester.pump();
    expect(find.text('Nét 1/6'), findsOneWidget);
    expect(painter().progress, 1);
    await tester.tap(find.byTooltip('Nét trước'));
    await tester.pump();
    expect(find.text('Nét 0/6'), findsOneWidget);
    expect(painter().progress, 6);
    await tester.tap(find.text('Tự vẽ'));
    await tester.pump();
    expect(
      painter().progress,
      0,
      reason: 'animation zero is blank, unlike static zero',
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Tạm dừng'), findsOneWidget);
    await tester.tap(find.text('Tạm dừng'));
    await tester.pump();
    expect(find.text('Phát'), findsOneWidget);
    await tester.tap(find.text('Vẽ lại'));
    await tester.pump();
    expect(find.text('Tạm dừng'), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(body: KanjiStrokeAnimator(document: document)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Đang bật giảm chuyển động.'), findsOneWidget);
    expect(find.textContaining('Nét '), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'independent repeated components stop playback and lock controls at zero',
      (tester) async {
    final document = StrokeDocument.parse(sampleSvg, kanjivgCommit: 'test');
    const components = [
      KanjiComponentOccurrence(
        id: 'b',
        form: '木',
        strokeIds: ['s2', 's4'],
        sortOrder: 1,
        kanjivgCommit: 'test',
      ),
      KanjiComponentOccurrence(
        id: 'a',
        form: '木',
        strokeIds: ['s1', 's3'],
        sortOrder: 0,
        kanjivgCommit: 'test',
      ),
      KanjiComponentOccurrence(
        id: 'extra',
        strokeIds: ['s5', 's6'],
        sortOrder: 2,
        kanjivgCommit: 'test',
      ),
    ];
    Widget host(StrokeDocument doc, Brightness brightness) => MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(
            body: KanjiStrokeAnimator(document: doc, components: components),
          ),
        );
    KanjiStrokePainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<KanjiStrokePainter>()
        .singleWhere((p) => p.drawGrid);
    final a = find.byKey(const ValueKey('component:a'));
    final b = find.byKey(const ValueKey('component:b'));
    final extra = find.byKey(const ValueKey('component:extra'));
    await tester.pumpWidget(host(document, Brightness.light));
    expect(
      orderKanjiComponents(components).map((c) => c.id),
      ['a', 'b', 'extra'],
    );
    expect(find.text('Thành phần'), findsOneWidget);
    expect(find.text('Thành phần theo thứ tự viết'), findsNothing);
    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('木'), findsAtLeastNWidgets(2));
    semantics.dispose();
    expect(find.text('Nét phụ'), findsOneWidget);
    expect(tester.getSize(a).height, 48);
    expect(tester.getSize(b).height, 48);
    expect(tester.getSize(extra).height, 48);
    expect(
      tester.getTopLeft(a).dx,
      closeTo(tester.getTopLeft(find.text('Thành phần')).dx, 0.01),
    );
    final previewPainters = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<KanjiStrokePainter>()
        .where((p) => !p.drawGrid)
        .toList();
    expect(previewPainters, hasLength(1));
    expect(
      previewPainters.single.ink,
      Theme.of(tester.element(extra)).colorScheme.onSurface,
    );
    expect(previewPainters.single.strokeWidth, 6);
    expect(previewPainters.single.fitToStrokeBounds, isTrue);
    final preview = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is KanjiStrokePainter &&
          (widget.painter as KanjiStrokePainter).onlyStrokeIds != null,
    );
    expect(tester.getSize(preview), const Size(28, 28));
    expect(tester.getSize(find.byType(OverflowBox)), const Size(28, 18));
    await tester.tap(find.text('Tự vẽ'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(a);
    await tester.pumpAndSettle();
    expect(find.text('Nét 0/6'), findsOneWidget);
    expect(find.text('Tạm dừng'), findsNothing);
    expect(painter().progress, 6);
    expect(painter().highlightedStrokeIds, {'s1', 's3'});
    expect(painter().highlightColor, const Color(0xFFD32F2F));
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Nét tiếp',
            ),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .onSelectionChanged,
      isNull,
    );
    await tester.tap(b);
    await tester.pump();
    expect(tester.widget<ChoiceChip>(a).selected, isFalse);
    expect(tester.widget<ChoiceChip>(b).selected, isTrue);
    expect(painter().highlightedStrokeIds, {'s2', 's4'});
    await tester.tap(b);
    await tester.pump();
    expect(painter().highlightedStrokeIds, isEmpty);
    expect(find.text('Nét 0/6'), findsOneWidget);
    await tester.tap(find.byTooltip('Nét tiếp'));
    await tester.pump();
    await tester.tap(a);
    await tester.pump();
    expect(find.text('Nét 0/6'), findsOneWidget);
    await tester.tap(find.text('Bỏ chọn'));
    await tester.pump();
    expect(painter().highlightedStrokeIds, isEmpty);
    expect(find.text('Nét 0/6'), findsOneWidget);
    await tester.tap(a);
    await tester.pumpWidget(host(document, Brightness.dark));
    await tester.pumpAndSettle();
    expect(painter().highlightColor, const Color(0xFFFF6B6B));
    expect(painter().highlightedStrokeIds, {'s1', 's3'});
    await tester.pumpWidget(
      host(
        StrokeDocument.parse(sampleSvg, kanjivgCommit: 'test'),
        Brightness.dark,
      ),
    );
    await tester.pumpAndSettle();
    expect(painter().highlightedStrokeIds, isEmpty);
    expect(find.text('Nét 0/6'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byTooltip('Nét tiếp'));
      await tester.pump();
    }
    expect(find.text('Nét 6/6'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(
            find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == 'Nét tiếp',
            ),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
      'mismatched source or path IDs disable highlighting without guessing',
      (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KanjiStrokeAnimator(
            document: StrokeDocument.parse(sampleSvg, kanjivgCommit: 'test'),
            components: const [
              KanjiComponentOccurrence(
                id: 'wrong-source',
                form: '木',
                strokeIds: ['s1'],
                sortOrder: 0,
                kanjivgCommit: 'old',
              ),
              KanjiComponentOccurrence(
                id: 'wrong-id',
                form: '木',
                strokeIds: ['missing'],
                sortOrder: 1,
                kanjivgCommit: 'test',
              ),
            ],
            onRetry: () => retries++,
          ),
        ),
      ),
    );
    expect(
      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .every((c) => c.onSelected == null),
      isTrue,
    );
    expect(find.textContaining('Chưa thể tô nét'), findsOneWidget);
    await tester.tap(find.text('Tải lại nét'));
    expect(retries, 1);
    expect(find.text('Nét 0/6'), findsOneWidget);
  });
  testWidgets('unsupported animation falls back to cumulative static SVG steps',
      (tester) async {
    final document = StrokeDocument.parse(
      sampleSvg.replaceFirst(
        '<g>',
        '<g transform="translate(1,1)">',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KanjiStrokeAnimator(document: document)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SVG này chỉ hỗ trợ xem từng nét.'), findsOneWidget);
    await tester.tap(find.byTooltip('Nét tiếp'));
    await tester.pumpAndSettle();
    expect(find.text('Nét 1/6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test(
    'all 2136 locked KanjiVG SVGs render with the same parser used in app',
    () {
      final data =
          jsonDecode(File('tool/kanji/.cache/catalog.json').readAsStringSync())
              as Map;
      final source =
          jsonDecode(File('assets/kanji/sources.json').readAsStringSync())
              as Map;
      final zip = ZipDecoder()
          .decodeBytes(File('tool/kanji/.cache/kanjivg.zip').readAsBytesSync());
      final files = {for (final f in zip.files) f.name: f};
      final occurrences = jsonDecode(
        File('tool/kanji/.cache/component_occurrences.json').readAsStringSync(),
      ) as List;
      for (final row in data['kanji'] as List) {
        final file = (row['id'] as int).toRadixString(16).padLeft(5, '0');
        final raw = utf8.decode(
          files['kanjivg-${source['kanjivg_commit']}/kanji/$file.svg']!.content
              as List<int>,
        );
        final doc = StrokeDocument.parse(
          raw,
          kanjivgCommit: source['kanjivg_commit'] as String,
        );
        final selected = occurrences.where((o) => o['kanji_id'] == row['id']);
        final ids = selected.expand((o) => o['stroke_ids'] as List).toList();
        expect(
          ids.toSet(),
          doc.strokeIds.toSet(),
          reason: row['character'] as String,
        );
        expect(
          ids.length,
          doc.strokeCount,
          reason: 'No overlapping occurrences',
        );
        expect(
          selected.every((o) => o['kanjivg_commit'] == doc.kanjivgCommit),
          isTrue,
        );
        expect(
          doc.paths.length,
          greaterThan(0),
          reason: row['character'] as String,
        );
      }
    },
    skip: !const bool.fromEnvironment('KANJI_CORPUS'),
  );
}
