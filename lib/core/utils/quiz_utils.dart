import '../database/app_database.dart';

const quizScriptKanji = 'kanji';
const quizScriptKana = 'kana';

String japaneseForQuiz(VocabularyEntry vocab, String script) {
  if (script == quizScriptKana) {
    return vocab.kana.trim();
  }
  final kanji = vocab.kanji?.trim();
  return kanji == null || kanji.isEmpty ? vocab.kana.trim() : kanji;
}

bool matchesJapaneseAnswer(
  VocabularyEntry vocab,
  String script,
  String answer,
) {
  return normalizeQuizAnswer(answer) ==
      normalizeQuizAnswer(japaneseForQuiz(vocab, script));
}

String normalizeQuizAnswer(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
