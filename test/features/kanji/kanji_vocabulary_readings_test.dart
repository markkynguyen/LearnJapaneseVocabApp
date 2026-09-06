import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/kanji/domain/kanji_models.dart';
import 'package:jvocab/features/kanji/domain/kanji_vocabulary_readings.dart';

void main() {
  const classifier = KanjiVocabularyReadingClassifier();

  test('groups single Kanji and compound under canonical Kun and On readings',
      () {
    final ane = _kanji('姉', on: ['シ'], kun: ['あね', 'はは']);
    final result = classifier.classify(
      target: ane,
      vocabulary: [
        _vocab('single', '姉', 'あね', 'chị gái'),
        _vocab('compound', '姉妹', 'しまい', 'chị em'),
      ],
      catalog: {
        '姉': ane,
        '妹': _kanji('妹', on: ['マイ'], kun: ['いもうと']),
      },
    );

    expect(_words(result.onyomi, 'シ'), ['姉妹']);
    expect(_words(result.kunyomi, 'あね'), ['姉']);
    expect(_words(result.kunyomi, 'はは'), isEmpty);
    expect(result.unknown, isEmpty);
  });

  test('supports okurigana, sokuon and rendaku', () {
    final yasumu = _kanji('休', on: ['キュウ'], kun: ['やす.む']);
    final school = _kanji('学', on: ['ガク'], kun: ['まな.ぶ']);
    final paper = _kanji('紙', on: ['シ'], kun: ['かみ']);

    final rest = classifier.classify(
      target: yasumu,
      vocabulary: [_vocab('rest', '休む', 'やすむ', 'nghỉ')],
      catalog: {'休': yasumu},
    );
    final schoolResult = classifier.classify(
      target: school,
      vocabulary: [_vocab('school', '学校', 'がっこう', 'trường học')],
      catalog: {
        '学': school,
        '校': _kanji('校', on: ['コウ'], kun: const []),
      },
    );
    final paperResult = classifier.classify(
      target: paper,
      vocabulary: [_vocab('letter', '手紙', 'てがみ', 'thư')],
      catalog: {
        '手': _kanji('手', on: ['シュ'], kun: ['て']),
        '紙': paper,
      },
    );

    expect(_words(rest.kunyomi, 'やす.む'), ['休む']);
    expect(_words(schoolResult.onyomi, 'ガク'), ['学校']);
    expect(_words(paperResult.kunyomi, 'かみ'), ['手紙']);
  });

  test('keeps irregular, incomplete and ambiguous alignments unknown', () {
    final today = _kanji('今', on: ['コン', 'キン'], kun: ['いま']);
    final ambiguous = _kanji('生', on: ['セイ'], kun: ['せい']);

    final irregular = classifier.classify(
      target: today,
      vocabulary: [_vocab('today', '今日', 'きょう', 'hôm nay')],
      catalog: {
        '今': today,
        '日': _kanji('日', on: ['ニチ', 'ジツ'], kun: ['ひ', 'か']),
      },
    );
    final missingCatalog = classifier.classify(
      target: today,
      vocabulary: [_vocab('missing', '今𠮷', 'いまよし', 'tên riêng')],
      catalog: {'今': today},
    );
    final ambiguousResult = classifier.classify(
      target: ambiguous,
      vocabulary: [_vocab('life', '生', 'せい', 'sống')],
      catalog: {'生': ambiguous},
    );

    expect(irregular.unknown.single.kanji, '今日');
    expect(missingCatalog.unknown.single.kanji, '今𠮷');
    expect(ambiguousResult.unknown.single.kanji, '生');
  });

  test('deduplicates display values, sorts by Kana and handles repetition mark',
      () {
    final time = _kanji('時', on: ['ジ'], kun: ['とき']);
    final result = classifier.classify(
      target: time,
      vocabulary: [
        _vocab('later', '時', 'とき', 'thời gian', createdAt: 1),
        _vocab('repeat', '時々', 'ときどき', 'thỉnh thoảng'),
        _vocab('new-copy', '時', 'とき', 'thời gian', createdAt: 3),
      ],
      catalog: {'時': time},
    );

    expect(_words(result.kunyomi, 'とき'), ['時', '時々']);
    expect(_group(result.kunyomi, 'とき').vocabulary.first.id, 'new-copy');
    expect(result.kunyomiCount, 2);
  });
}

KanjiVocabularyReadingGroup _group(
  List<KanjiVocabularyReadingGroup> groups,
  String reading,
) =>
    groups.singleWhere((group) => group.reading == reading);

List<String?> _words(
  List<KanjiVocabularyReadingGroup> groups,
  String reading,
) =>
    _group(groups, reading).vocabulary.map((vocab) => vocab.kanji).toList();

Kanji _kanji(
  String character, {
  required List<String> on,
  required List<String> kun,
}) =>
    Kanji(
      id: character.runes.single,
      character: character,
      onyomi: on,
      kunyomi: kun,
      meaningEn: 'test',
      strokeCount: 1,
      grade: 1,
      primaryRadicalId: 1,
    );

VocabularyEntry _vocab(
  String id,
  String kanji,
  String kana,
  String meaning, {
  int createdAt = 0,
}) =>
    VocabularyEntry(
      id: id,
      folderId: 'folder',
      kanji: kanji,
      kana: kana,
      romaji: 'test',
      meaning: meaning,
      isFavorite: false,
      createdAt: createdAt,
    );
