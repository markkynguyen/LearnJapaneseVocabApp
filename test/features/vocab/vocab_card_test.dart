import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/vocab/presentation/flashcard_screen.dart';
import 'package:jvocab/features/vocab/presentation/providers/flashcard_provider.dart';
import 'package:jvocab/features/vocab/presentation/widgets/pitch_accent_text.dart';
import 'package:jvocab/features/vocab/presentation/widgets/vocab_card.dart';

void main() {
  testWidgets('vocab card fits a mobile viewport and separates kana and romaji',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                VocabCard(
                  item: _item(),
                  onToggleFavorite: () {},
                  onAction: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<PitchAccentText>(find.byType(PitchAccentText)).kana,
      'たべる',
    );
    expect(find.text('taberu'), findsOneWidget);
    expect(find.text('Chưa ôn lần nào'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('consecutive high pitch mora render as one muted line',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PitchAccentText(
            kana: 'たべる',
            pattern: 'HHL',
            textColor: Colors.green,
            overlayAccent: true,
          ),
        ),
      ),
    );

    final positioned = tester.widgetList<Positioned>(
      find.descendant(
        of: find.byType(PitchAccentText),
        matching: find.byType(Positioned),
      ),
    );
    expect(positioned, hasLength(1));
    expect(positioned.single.left, 0);
    expect(positioned.single.right, isNull);
    expect(positioned.single.width, greaterThan(0));

    final lines = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(PitchAccentText),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final colors =
        lines.map((line) => (line.decoration! as BoxDecoration).color).toList();
    expect(
      colors,
      [
        Colors.green.withValues(alpha: 0.5),
      ],
    );
    expect(
      tester
          .getSize(
            find
                .descendant(
                  of: find.byType(PitchAccentText),
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          )
          .height,
      1.5,
    );
  });

  testWidgets('large compound kana keep spacing while pitch line stays joined',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: PitchAccentText(
                kana: 'べんきょうします',
                pattern: 'LHHHHLL',
                fontSize: 44,
                overlayAccent: true,
              ),
            ),
          ),
        ),
      ),
    );

    final lineFinder = find.descendant(
      of: find.byType(PitchAccentText),
      matching: find.byType(AnimatedContainer),
    );
    expect(lineFinder, findsOneWidget);

    final kyoRect = tester.getRect(find.text('きょ'));
    final uRect = tester.getRect(find.text('う'));
    expect(kyoRect.right <= uRect.left, isTrue);
    expect(tester.getSize(find.text('きょ')).width, greaterThan(40));
  });

  testWidgets('kana-only flashcard renders pitch accent as its title',
      (tester) async {
    final item = _item(kanji: null);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flashcardVocabularyProvider('folder-1').overrideWith(
            (ref) => [item],
          ),
        ],
        child: const MaterialApp(
          home: FlashcardScreen(folderId: 'folder-1', folderName: 'N5'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final pitch = tester.widget<PitchAccentText>(
      find.byWidgetPredicate(
        (widget) => widget is PitchAccentText && widget.fontSize == 44,
      ),
    );
    expect(pitch.kana, 'たべる');
    expect(pitch.pattern, 'HHL');
    expect(
      tester.widget<Text>(find.text('taberu')).style?.fontSize,
      Theme.of(tester.element(find.text('taberu')))
          .textTheme
          .titleLarge
          ?.fontSize,
    );
    expect(
      find.descendant(
        of: find.byType(Card),
        matching: find.byIcon(Icons.style_rounded),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('flashcard matches detail typography when a kanji is present',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flashcardVocabularyProvider('folder-1').overrideWith(
            (ref) => [_item()],
          ),
        ],
        child: const MaterialApp(
          home: FlashcardScreen(folderId: 'folder-1', folderName: 'N5'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final kanjiFinder = find.text('食べる');
    expect(
      tester.widget<Text>(kanjiFinder).style?.fontSize,
      Theme.of(tester.element(kanjiFinder)).textTheme.displayMedium?.fontSize,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is PitchAccentText && widget.fontSize == 30,
      ),
      findsOneWidget,
    );
  });

  testWidgets('missing pitch pattern falls back to plain kana', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PitchAccentText(kana: 'たべる', pattern: null),
        ),
      ),
    );

    expect(find.text('たべる'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNothing);
  });

  testWidgets('favorite override updates the card icon immediately',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: VocabCard(
              item: _item(),
              isFavoriteOverride: true,
              onToggleFavorite: () {},
              onAction: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });
}

VocabWithProgress _item({String? kanji = '食べる'}) {
  return VocabWithProgress(
    vocab: VocabularyEntry(
      id: 'vocab-1',
      folderId: 'folder-1',
      kanji: kanji,
      kana: 'たべる',
      romaji: 'taberu',
      meaning: 'ăn',
      pitchAccent: 'HHL',
      note: 'Động từ nhóm 2',
      isFavorite: false,
      createdAt: 0,
    ),
    progress: const SrsProgressEntry(
      vocabId: 'vocab-1',
      level: 0,
      intervalDays: 0,
      nextReviewAt: 0,
      correctCount: 0,
      wrongCount: 0,
    ),
  );
}
