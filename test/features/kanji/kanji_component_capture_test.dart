import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/features/kanji/data/kanji_stroke_service.dart';
import 'package:jvocab/features/kanji/domain/kanji_models.dart';
import 'package:jvocab/features/kanji/presentation/widgets/kanji_stroke_animator.dart';
import 'kanji_ui_test.dart' show capture;

void main() {
  testWidgets(
      'real corpus component highlighting in both themes and SVG fallback',
      (tester) async {
    await (FontLoader('KleeOne')
          ..addFont(rootBundle.load('assets/fonts/KleeOne-Regular.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    await (FontLoader('QaLatin')
          ..addFont(Future.value(ByteData.sublistView(
              File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),),),))
        .load();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final catalog =
        jsonDecode(File('tool/kanji/.cache/catalog.json').readAsStringSync())
            as Map;
    final source =
        jsonDecode(File('assets/kanji/sources.json').readAsStringSync()) as Map;
    final occurrences = jsonDecode(
        File('tool/kanji/.cache/component_occurrences.json')
            .readAsStringSync(),) as List;
    final zip = ZipDecoder()
        .decodeBytes(File('tool/kanji/.cache/kanjivg.zip').readAsBytesSync());
    final files = {for (final f in zip.files) f.name: f};
    for (final character in ['機', '何', '学', '森', '国', '基']) {
      final code = character.runes.single.toRadixString(16).padLeft(5, '0');
      final raw = utf8.decode(
          files['kanjivg-${source['kanjivg_commit']}/kanji/$code.svg']!.content
              as List<int>,);
      final components = occurrences
          .where((o) => o['kanji_id'] == character.runes.single)
          .map((o) {
        final json = Map<String, dynamic>.from(o as Map);
        if (json['radical_id'] != null) {
          json['radicals'] = (catalog['radicals'] as List)
              .singleWhere((r) => r['id'] == json['radical_id']);
        }
        return KanjiComponentOccurrence.fromJson(json);
      }).toList();
      final index =
          {'機': 2, '何': 3, '学': 0, '森': 1, '国': 0, '基': 1}[character]!;
      for (final brightness in Brightness.values) {
        for (final fallback in [false, if (character == '国') true]) {
          final document = StrokeDocument.parse(
            fallback
                ? raw.replaceFirst('viewBox="0 0 109 109"',
                    'viewBox="0 0 109 109" transform="translate(0,0)"',)
                : raw,
            kanjivgCommit: source['kanjivg_commit'] as String,
          );
          expect(document.supportsAnimation, !fallback);
          final key = GlobalKey();
          await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: brightness,
                fontFamily: 'QaLatin',
                colorSchemeSeed: const Color(0xFF6366F1),),
            home: RepaintBoundary(
                key: key,
                child: Scaffold(
                  appBar: AppBar(
                      title: Text('Thứ tự nét — $character',
                          style: const TextStyle(
                              fontFamilyFallback: ['KleeOne'],),),),
                  body: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: KanjiStrokeAnimator(
                          document: document, components: components,),),
                ),),
          ),);
          await tester.pumpAndSettle();
          expect(find.text('Nét 0/${document.strokeCount}'), findsOneWidget);
          await tester
              .tap(find.byKey(ValueKey('component:${components[index].id}')));
          await tester.pumpAndSettle();
          expect(find.text('Bỏ chọn'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await capture(tester, key,
              '${code}_${brightness.name}${fallback ? '_fallback' : ''}',);
        }
      }
    }
  },
      skip: !(const bool.fromEnvironment('KANJI_CORPUS') &&
          const bool.fromEnvironment('KANJI_CAPTURE')),);
}
