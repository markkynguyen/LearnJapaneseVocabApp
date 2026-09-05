import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jvocab/features/kanji/data/kanji_stroke_service.dart';
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
    expect('<path'.allMatches(transformed.staticSvgAt(2)).length, 2);
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
    expect(find.text('Nét 1/6'), findsOneWidget);
    await tester.tap(find.byTooltip('Nét tiếp'));
    await tester.pump();
    expect(find.text('Nét 2/6'), findsOneWidget);
    await tester.tap(find.text('Tự vẽ'));
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
    expect(find.text('Nét 2/6'), findsOneWidget);
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
      for (final row in data['kanji'] as List) {
        final file = (row['id'] as int).toRadixString(16).padLeft(5, '0');
        final raw = utf8.decode(
          files['kanjivg-${source['kanjivg_commit']}/kanji/$file.svg']!.content
              as List<int>,
        );
        final doc = StrokeDocument.parse(raw);
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
