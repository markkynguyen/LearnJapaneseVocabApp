import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/database/app_database.dart';
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
}

VocabWithProgress _item() {
  return const VocabWithProgress(
    vocab: VocabularyEntry(
      id: 1,
      folderId: 1,
      kanji: '食べる',
      kana: 'たべる',
      romaji: 'taberu',
      meaning: 'ăn',
      pitchAccent: 'HHL',
      note: 'Động từ nhóm 2',
      isFavorite: false,
      createdAt: 0,
    ),
    progress: SrsProgressEntry(
      id: 1,
      vocabId: 1,
      level: 0,
      intervalDays: 0,
      nextReviewAt: 0,
      correctCount: 0,
      wrongCount: 0,
    ),
  );
}
