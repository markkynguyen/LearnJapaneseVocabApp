import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/features/kanji/data/kanji_stroke_service.dart';
import 'package:jvocab/features/kanji/domain/kanji_decomposition.dart';
import 'package:jvocab/features/kanji/domain/kanji_models.dart';
import 'package:jvocab/features/kanji/presentation/widgets/kanji_decomposition_viewer.dart';
import 'package:jvocab/features/kanji/presentation/widgets/kanji_stroke_animator.dart';
import 'kanji_ui_test.dart' show capture;

void main() {
  testWidgets(
    'capture nested decomposition using real root SVGs',
    (tester) async {
      await (FontLoader('KleeOne')
            ..addFont(rootBundle.load('assets/fonts/KleeOne-Regular.ttf')))
          .load();
      await (FontLoader('MaterialIcons')
            ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
          .load();
      await (FontLoader('QaLatin')
            ..addFont(
              Future.value(
                ByteData.sublistView(
                  File('C:/Windows/Fonts/segoeui.ttf').readAsBytesSync(),
                ),
              ),
            ))
          .load();
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rows = jsonDecode(
        File('tool/kanji/.cache/decompositions.json').readAsStringSync(),
      ) as List;
      final trees = {
        for (final row in rows)
          (row as Map)['kanji_id']:
              KanjiDecomposition.fromJson(Map<String, dynamic>.from(row)),
      };
      final catalog =
          jsonDecode(File('tool/kanji/.cache/catalog.json').readAsStringSync())
              as Map;
      final meanings = {
        for (final row in catalog['kanji'] as List)
          (row as Map)['character'] as String:
              Kanji.fromJson(Map<String, dynamic>.from(row)),
      };
      final archive = ZipDecoder()
          .decodeBytes(File('tool/kanji/.cache/kanjivg.zip').readAsBytesSync());
      final files = {for (final file in archive.files) file.name: file};
      for (final char in [
        '想',
        '謝',
        '森',
        '語',
        '憾',
        '機',
        '孝',
        '座',
        '学',
        '王',
        '良',
      ]) {
        final tree = trees[char.runes.single]!;
        final code = char.runes.single.toRadixString(16).padLeft(5, '0');
        final svg = utf8.decode(
          files['kanjivg-${tree.kanjivgCommit}/kanji/$code.svg']!.content
              as List<int>,
        );
        for (final brightness in Brightness.values) {
          for (final fallback in [
            false,
            if (['語', '孝', '座'].contains(char)) true,
          ]) {
            final doc = StrokeDocument.parse(
              fallback
                  ? svg.replaceFirst(
                      'viewBox="0 0 109 109"',
                      'viewBox="0 0 109 109" transform="translate(0,0)"',
                    )
                  : svg,
              kanjivgCommit: tree.kanjivgCommit,
            );
            final boundary = GlobalKey();
            RadicalForm? openedRadical;
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(
                  brightness: brightness,
                  fontFamily: 'QaLatin',
                  colorSchemeSeed: const Color(0xFF6366F1),
                ),
                home: RepaintBoundary(
                  key: boundary,
                  child: Scaffold(
                    body: Dialog(
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: SizedBox(
                        height: 726,
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Phân tích Hán tự',
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                            Expanded(
                              child: KanjiDecompositionPanel(
                                key: ValueKey('$char:$brightness:$fallback'),
                                tree: tree,
                                document: doc,
                                hanVietLabel:
                                    meanings[char]!.hanViet!.toUpperCase(),
                                meanings: meanings,
                                onRadicalForm: (form) => openedRadical = form,
                                details: Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: Text(
                                    'Nghĩa tiếng Việt\n${meanings[char]!.meaningVi}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final first = tree.root.children.isEmpty
                ? tree.root
                : tree.root.children.firstWhere(
                    (n) => n.kind == KanjiComponentKind.kanji,
                    orElse: () => tree.root.children.first,
                  );
            await tester
                .tap(find.byKey(ValueKey('tree-component:${first.id}')));
            await tester.pumpAndSettle();
            if (first.children.isNotEmpty) {
              expect(find.text('Thành phần của ${first.form}'), findsOneWidget);
            }
            if (char == '孝') {
              expect(first.label, '耂 Lão');
              expect(first.radicalForm!.form, '耂');
              expect(first.radicalForm!.radical.character, '老');
              expect(find.text('Đang chọn: 耂 Lão'), findsOneWidget);
              expect(find.text('Đang chọn: 老 Lão'), findsNothing);
              await tester.ensureVisible(find.text('Chi tiết bộ thủ 耂 Lão'));
              await tester.tap(find.text('Chi tiết bộ thủ 耂 Lão'));
              expect(openedRadical!.form, '耂');
              expect(openedRadical!.radical.id, 125);
              final painters = tester
                  .widgetList<CustomPaint>(find.byType(CustomPaint))
                  .map((w) => w.painter)
                  .whereType<KanjiStrokePainter>();
              if (!fallback) {
                expect(
                  painters.first.highlightedStrokeIds,
                  first.strokeIds.toSet(),
                );
              }
            }
            await capture(
              tester,
              boundary,
              'tree_${code}_${brightness.name}_${fallback ? 'static' : 'paths'}',
            );
            if (char == '座') {
              final humans =
                  tree.root.children.where((n) => n.form == '人').toList();
              expect(humans, hasLength(2));
              for (final human in humans) {
                await tester
                    .tap(find.byKey(ValueKey('tree-component:${human.id}')));
                await tester.pumpAndSettle();
                if (!fallback) {
                  final painter = tester
                      .widgetList<CustomPaint>(find.byType(CustomPaint))
                      .map((w) => w.painter)
                      .whereType<KanjiStrokePainter>()
                      .first;
                  expect(painter.highlightedStrokeIds, human.strokeIds.toSet());
                }
              }
              await capture(
                tester,
                boundary,
                'tree_${code}_${brightness.name}_${fallback ? 'static' : 'paths'}_human',
              );
            }
            if (first.children.isEmpty) {
              expect(tester.takeException(), isNull);
              continue;
            }
            final child = first.children.firstWhere(
              (n) => n.children.isNotEmpty,
              orElse: () => first.children.first,
            );
            await tester.ensureVisible(
              find.byKey(ValueKey('tree-component:${child.id}')),
            );
            await tester
                .tap(find.byKey(ValueKey('tree-component:${child.id}')));
            await tester.pumpAndSettle();
            await capture(
              tester,
              boundary,
              'tree_${code}_${brightness.name}_${fallback ? 'static' : 'paths'}_deep',
            );
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
    skip: !const bool.fromEnvironment('KANJI_CAPTURE'),
  );
}
