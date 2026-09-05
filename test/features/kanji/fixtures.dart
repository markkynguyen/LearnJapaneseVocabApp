const sampleSvg =
    '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 109 109">
<g id="kvg:StrokePaths_04f11"><g><path d="M 30,15 C 30,30 20,40 10,50"/>
<path d="M 24,34 L 24,95"/><path d="M 40,40 L 95,40"/>
<path d="M 68,10 L 68,95"/><path d="M 65,40 C 60,60 45,80 34,87"/>
<path d="M 71,42 C 76,60 90,80 100,86"/></g></g>
<g id="kvg:StrokeNumbers_04f11"><text x="20" y="10">1</text></g></svg>''';

Map<String, dynamic> kanjiJson(String char, {int count = 1}) => {
      'id': char.runes.single,
      'character': char,
      'han_viet': char == '休'
          ? 'Hưu'
          : char == '生'
              ? 'Sinh'
              : 'Tiên',
      'meaning_vi': char == '休'
          ? 'Nghỉ ngơi'
          : char == '生'
              ? 'Sống; sinh ra'
              : 'Trước; đi trước',
      'meaning_en': 'rest',
      'onyomi': ['キュウ'],
      'kunyomi': ['やす.む'],
      'stroke_count': 6,
      'grade': 1,
      'primary_radical_id': 9,
      'count': count,
      'translation_reviewed': false,
    };
Map<String, dynamic> radicalJson({int count = 1}) => {
      'id': 9,
      'character': '人',
      'name_vi': 'Nhân',
      'meaning_vi': 'Người',
      'stroke_count': 2,
      'variants': ['亻'],
      'positions': ['Trái'],
      'count': count,
    };
Map<String, dynamic> snapshotJson({bool empty = false}) => {
      'overview': empty
          ? null
          : {
              'last_calculated_at': '2020-01-01T12:00:00Z',
              'total_kanji_count': 3,
              'total_radical_count': 1,
              'total_vocab_scanned': 8,
              'unsupported_kanji_count': 1,
            },
      'kanji': empty
          ? []
          : [
              kanjiJson('休', count: 12),
              kanjiJson('先', count: 8),
              kanjiJson('生', count: 2),
            ],
      'radicals': empty ? [] : [radicalJson(count: 12)],
    };
