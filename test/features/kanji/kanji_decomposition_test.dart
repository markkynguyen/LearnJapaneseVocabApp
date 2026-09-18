import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/features/kanji/data/kanji_repository.dart';
import 'package:jvocab/features/kanji/data/kanji_stroke_service.dart';
import 'package:jvocab/features/kanji/domain/kanji_decomposition.dart';
import 'package:jvocab/features/kanji/domain/kanji_models.dart';
import 'package:jvocab/features/kanji/presentation/widgets/kanji_decomposition_viewer.dart';
import 'package:jvocab/features/kanji/presentation/widgets/kanji_stroke_animator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kanji_data_test.dart' show FakeKanjiStore;

Map<String, dynamic> node(
  String id,
  String form,
  String kind,
  List<int> strokes, [
  List<Map<String, dynamic>> children = const [],
]) =>
    {
      'id': id,
      'display_form': form,
      'kind': kind,
      'radical_id':
          kind == 'radical' ? {'木': 75, '目': 109, '心': 61}[form] : null,
      'stroke_ids': strokes.map((s) => 's$s').toList(),
      'source_group_ids': [id],
      'children': children,
    };

Map<String, dynamic> treeJson() => {
      'kanji_id': '想'.runes.single,
      'structure_version': 3,
      'kanjivg_commit': 'test',
      'tree': node('root', '想', 'kanji', List.generate(13, (i) => i + 1), [
        node('xiang', '相', 'kanji', List.generate(9, (i) => i + 1), [
          node('wood', '木', 'radical', [1, 2, 3, 4]),
          node('eye', '目', 'radical', [5, 6, 7, 8, 9]),
        ]),
        node('heart', '心', 'radical', [10, 11, 12, 13]),
      ]),
    };

StrokeDocument drawing({
  String commit = 'test',
  bool fallback = false,
  int count = 13,
}) =>
    StrokeDocument.parse(
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 109 109"
    ${fallback ? 'transform="translate(0,0)"' : ''}>
    <g id="StrokePaths"><g id="root">
    ${List.generate(count, (i) => '<path id="s${i + 1}" d="M10 ${i * 6 + 10} L90 ${i * 6 + 10}"/>').join()}
    </g></g></svg>''',
      kanjivgCommit: commit,
    );

class TreeStore extends FakeKanjiStore {
  int treeReads = 0, meaningReads = 0;
  @override
  Future<Map<String, dynamic>?> getKanjiDecomposition(int id) async {
    treeReads++;
    return treeJson();
  }

  @override
  Future<List<Map<String, dynamic>>> getKanjiByCharacters(
    Iterable<String> characters,
  ) {
    meaningReads++;
    return super.getKanjiByCharacters(characters);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('rejects duplicate/omitted child strokes and unsupported versions', () {
    for (final invalid in [
      {...treeJson(), 'structure_version': 2},
      {
        ...treeJson(),
        'tree': node('root', '想', 'kanji', [
          1,
          2,
        ], [
          node('a', '木', 'radical', [1]),
          node('b', '木', 'radical', [1]),
        ]),
      },
    ]) {
      expect(() => KanjiDecomposition.fromJson(invalid), throwsFormatException);
    }
  });

  test('accepts sibling components that share a parent stroke', () {
    final overlap = {
      'kanji_id': '想'.runes.single,
      'structure_version': 3,
      'kanjivg_commit': 'test',
      'tree': node('root', '想', 'kanji', [
        1,
        2,
        3,
        4,
      ], [
        node('two', '木', 'radical', [1, 2]),
        node('open', '目', 'radical', [2, 3, 4]),
      ]),
    };
    expect(() => KanjiDecomposition.fromJson(overlap), returnsNormally);
  });

  test('branch tracks occurrence IDs, collapses descendants and clears', () {
    final tree = KanjiDecomposition.fromJson(treeJson());
    final selection = KanjiDecompositionSelection();
    final xiang = tree.root.children.first;
    selection.select(xiang, 0);
    selection.select(xiang.children.first, 1);
    expect(selection.branch, [xiang]);
    expect(selection.selected!.strokeIds, ['s1', 's2', 's3', 's4']);
    selection.select(tree.root.children.last, 0);
    expect(selection.branch, isEmpty);
    selection.select(xiang, 0);
    selection.select(xiang, 0);
    expect(selection.selected, isNull);
    expect(selection.branch, isEmpty);
    selection.select(xiang, 0);
    selection.clear();
    expect(selection.branch, isEmpty);
  });

  test('tree and batched meanings reopen offline without changing stats',
      () async {
    final store = TreeStore();
    final repository = KanjiRepository(store, 'one');
    final tree = (await repository.getKanjiDecomposition('想'.runes.single))!;
    final meanings = await repository.getDecompositionMeanings(tree);
    expect(meanings.keys, contains('相'));
    expect(store.meaningReads, 1);
    final offline = KanjiRepository(store, 'one', isOffline: () => true);
    final saved = (await offline.getKanjiDecomposition('想'.runes.single))!;
    expect(saved.root.children.first.form, '相');
    expect((await offline.getDecompositionMeanings(saved)).keys, contains('相'));
    expect(store.treeReads, 1);
    expect(store.meaningReads, 1);
    expect(store.recalculations, 0);
  });

  Widget panel(
    KanjiDecomposition tree, {
    StrokeDocument? document,
    double scale = 1,
    Brightness brightness = Brightness.light,
    bool reduceMotion = false,
    Map<String, Kanji> meanings = const {},
  }) =>
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(scale),
            size: const Size(390, 844),
            disableAnimations: reduceMotion,
          ),
          child: Scaffold(
            body: KanjiDecompositionPanel(
              tree: tree,
              document: document,
              hanVietLabel: 'TƯỞNG',
              meanings: meanings,
              details:
                  const SizedBox(height: 500, child: Text('Nghĩa chữ gốc')),
            ),
          ),
        ),
      );

  Finder chip(String id) => find.byKey(ValueKey('tree-component:$id'));
  KanjiStrokePainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((w) => w.painter)
      .whereType<KanjiStrokePainter>()
      .first;

  testWidgets(
      'opens one level, pins root, highlights child, swaps branches and resets',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tree = KanjiDecomposition.fromJson(treeJson());
    await tester.pumpWidget(panel(tree, document: drawing()));
    expect(chip('wood'), findsNothing);
    final top = tester.getTopLeft(find.byType(KanjiStrokeAnimator));
    await tester.tap(chip('xiang'));
    await tester.pumpAndSettle();
    expect(find.text('Thành phần của 相'), findsOneWidget);
    expect(
      painter(tester).highlightedStrokeIds,
      tree.root.children.first.strokeIds.toSet(),
    );
    expect(find.textContaining('Chưa có thông tin nghĩa'), findsOneWidget);
    await tester.tap(chip('wood'));
    await tester.pumpAndSettle();
    expect(painter(tester).highlightedStrokeIds, {'s1', 's2', 's3', 's4'});
    expect(tester.getTopLeft(find.byType(KanjiStrokeAnimator)), top);
    await tester.ensureVisible(chip('heart'));
    await tester.tap(chip('heart'));
    await tester.pumpAndSettle();
    expect(chip('wood'), findsNothing);
    expect(painter(tester).highlightedStrokeIds, {'s10', 's11', 's12', 's13'});
    await tester.tap(find.text('Về toàn chữ'));
    await tester.pumpAndSettle();
    expect(painter(tester).highlightedStrokeIds, isEmpty);
    expect(find.text('Nét 0/13'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection stops animation and locks controls until reset',
      (tester) async {
    await tester.pumpWidget(
      panel(KanjiDecomposition.fromJson(treeJson()), document: drawing()),
    );
    await tester.tap(find.text('Tự vẽ'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(chip('xiang'));
    await tester.pumpAndSettle();
    expect(find.text('Nét 0/13'), findsOneWidget);
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .onSelectionChanged,
      isNull,
    );
    await tester.tap(find.text('Về toàn chữ'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SegmentedButton<bool>>(find.byType(SegmentedButton<bool>))
          .onSelectionChanged,
      isNotNull,
    );
  });

  testWidgets('each overlapping chip highlights its complete stroke set',
      (tester) async {
    final overlap = KanjiDecomposition.fromJson({
      'kanji_id': '想'.runes.single,
      'structure_version': 3,
      'kanjivg_commit': 'test',
      'tree': node('root', '想', 'kanji', [
        1,
        2,
        3,
        4,
      ], [
        node('two', '木', 'radical', [1, 2]),
        node('open', '目', 'radical', [2, 3, 4]),
      ]),
    });
    await tester.pumpWidget(panel(overlap, document: drawing(count: 4)));
    await tester.tap(chip('two'));
    await tester.pumpAndSettle();
    expect(painter(tester).highlightedStrokeIds, {'s1', 's2'});
    await tester.tap(chip('open'));
    await tester.pumpAndSettle();
    expect(painter(tester).highlightedStrokeIds, {'s2', 's3', 's4'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('component chips show only the drawing and component name',
      (tester) async {
    await tester.pumpWidget(
      panel(KanjiDecomposition.fromJson(treeJson()), document: drawing()),
    );

    expect(find.text('Hán tự'), findsNothing);
    expect(find.text('Bộ thủ'), findsNothing);
    expect(
      find.descendant(of: chip('xiang'), matching: find.byIcon(Icons.check)),
      findsNothing,
    );
    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.byIcon(Icons.expand_less), findsNothing);
    expect(find.text('相'), findsNothing);
    expect(find.text('心'), findsOneWidget);
  });

  testWidgets('Kanji chip uses Han Viet name and leaves it blank when absent',
      (tester) async {
    final tuong = Kanji.fromJson({
      'id': '相'.runes.single,
      'character': '相',
      'han_viet': 'Tương',
      'onyomi': <String>[],
      'kunyomi': <String>[],
      'meaning_en': 'mutual',
      'stroke_count': 9,
      'grade': 3,
      'primary_radical_id': 75,
    });
    await tester.pumpWidget(
      panel(
        KanjiDecomposition.fromJson(treeJson()),
        document: drawing(),
        meanings: {'相': tuong},
      ),
    );

    expect(find.text('Tương'), findsOneWidget);
    expect(find.text('相'), findsNothing);
  });

  testWidgets('tree stays usable without matching SVG, reload resets selection',
      (tester) async {
    final tree = KanjiDecomposition.fromJson(treeJson());
    await tester.pumpWidget(panel(tree, document: drawing(commit: 'wrong')));
    await tester.tap(chip('xiang'));
    await tester.pumpAndSettle();
    expect(chip('wood'), findsOneWidget);
    expect(painter(tester).highlightedStrokeIds, isEmpty);
    await tester.pumpWidget(panel(tree));
    await tester.pumpAndSettle();
    expect(chip('wood'), findsOneWidget);
    await tester.pumpWidget(
      panel(KanjiDecomposition.fromJson(treeJson()), document: drawing()),
    );
    await tester.pumpAndSettle();
    expect(chip('wood'), findsNothing);
  });

  testWidgets(
      'small screen large text and dark reduced motion have no overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      panel(
        KanjiDecomposition.fromJson(treeJson()),
        document: drawing(),
        scale: 2,
        brightness: Brightness.dark,
        reduceMotion: true,
      ),
    );
    await tester.ensureVisible(chip('xiang'));
    await tester.tap(chip('xiang'));
    await tester.pumpAndSettle();
    expect(chip('wood'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'all generated trees parse and validate in client',
    () {
      final rows = jsonDecode(
        File('tool/kanji/.cache/decompositions.json').readAsStringSync(),
      ) as List;
      expect(rows.length, 2136);
      for (final row in rows) {
        KanjiDecomposition.fromJson(Map<String, dynamic>.from(row as Map));
      }
    },
    skip: !const bool.fromEnvironment('KANJI_CORPUS'),
  );
}
