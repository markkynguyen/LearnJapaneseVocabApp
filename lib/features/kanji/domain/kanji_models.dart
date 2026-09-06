/// Unicode scalar values, not UTF-16 code units. Keep SQL is_kanji_codepoint in sync.
bool isKanjiCodePoint(int cp) => const [
      (0x3400, 0x4DBF),
      (0x4E00, 0x9FFF),
      (0xF900, 0xFAFF),
      (0x20000, 0x2A6DF),
      (0x2A700, 0x2B73F),
      (0x2B740, 0x2B81F),
      (0x2B820, 0x2CEAF),
      (0x2CEB0, 0x2EBEF),
      (0x2EBF0, 0x2EE5F),
      (0x2F800, 0x2FA1F),
      (0x30000, 0x3134F),
      (0x31350, 0x323AF),
      (0x323B0, 0x3347F),
    ].any((range) => cp >= range.$1 && cp <= range.$2);

List<String> extractKanjiCharacters(String? text) => (text ?? '')
    .runes
    .where(isKanjiCodePoint)
    .map(String.fromCharCode)
    .toList();

List<String> _strings(dynamic value) =>
    (value as List? ?? const []).map((e) => e as String).toList();
int _integer(Map<String, dynamic> json, String key) =>
    (json[key] as num).toInt();

class Kanji {
  const Kanji({
    required this.id,
    required this.character,
    this.hanViet,
    required this.onyomi,
    required this.kunyomi,
    this.meaningVi,
    required this.meaningEn,
    required this.strokeCount,
    required this.grade,
    required this.primaryRadicalId,
    this.translationReviewed = false,
    this.count = 0,
  });

  factory Kanji.fromJson(Map<String, dynamic> json) => Kanji(
        id: _integer(json, 'id'),
        character: json['character'] as String,
        hanViet: json['han_viet'] as String?,
        onyomi: _strings(json['onyomi']),
        kunyomi: _strings(json['kunyomi']),
        meaningVi: json['meaning_vi'] as String?,
        meaningEn: json['meaning_en'] as String,
        strokeCount: _integer(json, 'stroke_count'),
        grade: _integer(json, 'grade'),
        primaryRadicalId: _integer(json, 'primary_radical_id'),
        translationReviewed: json['translation_reviewed'] == true,
        count: (json['count'] as num?)?.toInt() ?? 0,
      );

  final int id, strokeCount, grade, primaryRadicalId, count;
  final String character, meaningEn;
  final String? hanViet, meaningVi;
  final List<String> onyomi, kunyomi;
  final bool translationReviewed;
  String get gradeLabel => grade == 8 ? 'Trung học' : 'Lớp $grade';
}

class Radical {
  const Radical({
    required this.id,
    required this.character,
    required this.nameVi,
    required this.meaningVi,
    required this.strokeCount,
    this.variants = const [],
    this.positions = const [],
    this.count = 0,
  });
  factory Radical.fromJson(Map<String, dynamic> json) => Radical(
        id: _integer(json, 'id'),
        character: json['character'] as String,
        nameVi: json['name_vi'] as String,
        meaningVi: json['meaning_vi'] as String,
        strokeCount: _integer(json, 'stroke_count'),
        variants: _strings(json['variants']),
        positions: _strings(json['positions']),
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
  final int id, strokeCount, count;
  final String character, nameVi, meaningVi;
  final List<String> variants, positions;
}

class KanjiComponent {
  const KanjiComponent({
    required this.form,
    required this.radical,
    required this.sortOrder,
  });
  factory KanjiComponent.fromJson(Map<String, dynamic> json) => KanjiComponent(
        form: json['component_form'] as String,
        radical: Radical.fromJson(
          Map<String, dynamic>.from(json['radicals'] as Map),
        ),
        sortOrder: _integer(json, 'sort_order'),
      );
  final String form;
  final Radical radical;
  final int sortOrder;
}

class KanjiOverview {
  KanjiOverview.fromJson(Map<String, dynamic> json)
      : calculatedAt = DateTime.parse(json['last_calculated_at'] as String),
        kanjiCount = _integer(json, 'total_kanji_count'),
        radicalCount = _integer(json, 'total_radical_count'),
        vocabScanned = _integer(json, 'total_vocab_scanned'),
        unsupportedCount = _integer(json, 'unsupported_kanji_count'),
        componentVersion = (json['component_version'] as num?)?.toInt() ?? 1;
  final int componentVersion;
  bool get needsComponentUpdate => componentVersion < 2;
  final DateTime calculatedAt;
  final int kanjiCount, radicalCount, vocabScanned, unsupportedCount;
}

class KanjiComponentOccurrence {
  const KanjiComponentOccurrence({
    required this.id,
    required this.strokeIds,
    required this.sortOrder,
    required this.kanjivgCommit,
    this.form,
    this.radical,
    this.sourceElement,
    this.sourceOriginal,
    this.groupIds = const [],
    this.componentVersion = 2,
  });
  factory KanjiComponentOccurrence.fromJson(Map<String, dynamic> json) =>
      KanjiComponentOccurrence(
        id: json['occurrence_id'] as String,
        form: json['display_form'] as String?,
        strokeIds: _strings(json['stroke_ids']),
        groupIds: _strings(json['source_group_ids']),
        sourceElement: json['source_element'] as String?,
        sourceOriginal: json['source_original'] as String?,
        radical: json['radicals'] == null
            ? null
            : Radical.fromJson(
                Map<String, dynamic>.from(json['radicals'] as Map),
              ),
        sortOrder: _integer(json, 'sort_order'),
        componentVersion: _integer(json, 'component_version'),
        kanjivgCommit: json['kanjivg_commit'] as String,
      );
  final String id, kanjivgCommit;
  final String? form, sourceElement, sourceOriginal;
  final Radical? radical;
  final List<String> strokeIds, groupIds;
  final int sortOrder, componentVersion;
  String get label => form == null
      ? 'Nét phụ'
      : radical == null
          ? form!
          : '$form ${radical!.nameVi}';
}

class KanjiSnapshot {
  const KanjiSnapshot({
    this.overview,
    this.kanji = const [],
    this.radicals = const [],
    this.fromCache = false,
  });
  factory KanjiSnapshot.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) =>
      KanjiSnapshot(
        overview: json['overview'] == null
            ? null
            : KanjiOverview.fromJson(
                Map<String, dynamic>.from(json['overview'] as Map),
              ),
        kanji: (json['kanji'] as List)
            .map((r) => Kanji.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
        radicals: (json['radicals'] as List)
            .map((r) => Radical.fromJson(Map<String, dynamic>.from(r as Map)))
            .toList(),
        fromCache: fromCache,
      );
  final KanjiOverview? overview;
  final List<Kanji> kanji;
  final List<Radical> radicals;
  final bool fromCache;
}
