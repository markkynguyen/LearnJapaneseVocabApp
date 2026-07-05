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

  testWidgets('high pitch lines use kana color and fill each mora cell',
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
    expect(positioned, hasLength(3));
    expect(
      positioned.every((line) => line.left == 0 && line.right == 0),
      isTrue,
    );

    final lines = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(PitchAccentText),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final colors =
        lines.map((line) => (line.decoration! as BoxDecoration).color).toList();
    expect(colors, [Colors.green, Colors.green, Colors.transparent]);
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
        (widget) => widget is PitchAccentText && widget.fontSize == 36,
      ),
    );
    expect(pitch.kana, 'たべる');
    expect(pitch.pattern, 'HHL');
    expect(tester.takeException(), isNull);
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
