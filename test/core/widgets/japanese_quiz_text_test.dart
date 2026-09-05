import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/core/theme/app_theme.dart';
import 'package:jvocab/core/utils/quiz_utils.dart';
import 'package:jvocab/core/widgets/japanese_quiz_text.dart';

void main() {
  testWidgets('uses Klee One by default for Kanji quiz text', (tester) async {
    const kanji = '食べる';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: JapaneseQuizText(
            text: QuizJapaneseText(
              primary: kanji,
              acceptedAnswers: [kanji],
              usesKanji: true,
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(kanji));
    expect(text.style?.fontFamily, 'KleeOne');
  });

  testWidgets('uses the selected BIZ UDPGothic font for kana and Kanji',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(
          japaneseFont: JapaneseFontChoice.clearModern,
        ),
        home: const Scaffold(
          body: Column(
            children: [
              JapaneseQuizText(
                text: QuizJapaneseText(
                  primary: '食べる',
                  acceptedAnswers: ['食べる'],
                  usesKanji: true,
                ),
              ),
              JapaneseQuizText(
                text: QuizJapaneseText(
                  primary: 'たべる',
                  acceptedAnswers: ['たべる'],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    for (final text in ['食べる', 'たべる']) {
      expect(
        tester.widget<Text>(find.text(text)).style?.fontFamily,
        'BizUDPGothic',
      );
    }
  });

  test('marks Kanji quiz displays so their typography is preserved', () {
    final vocab = _vocabularyWithKanji();

    expect(japaneseDisplayForQuiz(vocab, quizScriptKanji).usesKanji, isTrue);
    expect(japaneseDisplayForQuiz(vocab, quizScriptBoth).usesKanji, isTrue);
    expect(japaneseDisplayForQuiz(vocab, quizScriptKana).usesKanji, isFalse);
  });
}

VocabularyEntry _vocabularyWithKanji() => const VocabularyEntry(
      id: 'vocab-1',
      folderId: 'folder-1',
      kanji: '食べる',
      kana: 'たべる',
      romaji: 'taberu',
      meaning: 'ăn',
      isFavorite: false,
      createdAt: 0,
    );
