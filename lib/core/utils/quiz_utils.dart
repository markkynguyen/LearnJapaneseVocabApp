import '../models/app_models.dart';

const quizScriptKanji = 'kanji';
const quizScriptKana = 'kana';
const quizScriptBoth = 'both';

class QuizJapaneseText {
  const QuizJapaneseText({
    required this.primary,
    this.secondary,
    required this.acceptedAnswers,
    this.usesKanji = false,
  });

  final String primary;
  final String? secondary;
  final List<String> acceptedAnswers;
  final bool usesKanji;

  bool get hasSecondary => secondary?.trim().isNotEmpty == true;
  String get plainText => hasSecondary ? '$primary\n$secondary' : primary;
}

class QuizChoice {
  const QuizChoice({
    required this.value,
    this.japaneseDisplay,
  });

  final String value;
  final QuizJapaneseText? japaneseDisplay;

  bool get isJapanese => japaneseDisplay != null;
}

QuizJapaneseText quizJapaneseTextFromPlain(String value) {
  final trimmed = value.trim();
  return QuizJapaneseText(primary: trimmed, acceptedAnswers: [trimmed]);
}

List<QuizChoice> quizChoicesFromObjects(Iterable<Object> choices) {
  return choices.map(quizChoiceFromObject).toList();
}

QuizChoice quizChoiceFromObject(Object choice) {
  if (choice is QuizChoice) {
    return choice;
  }
  if (choice is String) {
    return QuizChoice(value: choice);
  }
  throw ArgumentError.value(choice, 'choice', 'Expected String or QuizChoice');
}

String japaneseForQuiz(VocabularyEntry vocab, String script) {
  return japaneseDisplayForQuiz(vocab, script).primary;
}

QuizJapaneseText japaneseDisplayForQuiz(VocabularyEntry vocab, String script) {
  final kana = vocab.kana.trim();
  final kanji = vocab.kanji?.trim();
  final hasKanji = kanji != null && kanji.isNotEmpty;

  if (script == quizScriptKana || !hasKanji) {
    return QuizJapaneseText(primary: kana, acceptedAnswers: [kana]);
  }

  if (script == quizScriptBoth && kanji != kana) {
    return QuizJapaneseText(
      primary: kanji,
      secondary: kana,
      acceptedAnswers: [kanji, kana],
      usesKanji: true,
    );
  }

  return QuizJapaneseText(
    primary: kanji,
    acceptedAnswers: [kanji],
    usesKanji: true,
  );
}

List<String> acceptedJapaneseAnswersForQuiz(
  VocabularyEntry vocab,
  String script,
) {
  return japaneseDisplayForQuiz(vocab, script).acceptedAnswers;
}

bool matchesJapaneseAnswer(
  VocabularyEntry vocab,
  String script,
  String answer,
) {
  return matchesQuizJapaneseText(japaneseDisplayForQuiz(vocab, script), answer);
}

bool matchesQuizJapaneseText(QuizJapaneseText text, String answer) {
  final normalizedAnswer = normalizeQuizAnswer(answer);
  return text.acceptedAnswers
      .map(normalizeQuizAnswer)
      .contains(normalizedAnswer);
}

String normalizeQuizAnswer(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
