import '../../../core/models/app_models.dart';
import 'kanji_models.dart';

enum KanjiReadingType { on, kun, unknown }

class KanjiVocabularyReadingGroup {
  const KanjiVocabularyReadingGroup({
    required this.type,
    required this.reading,
    required this.vocabulary,
  });

  final KanjiReadingType type;
  final String reading;
  final List<VocabularyEntry> vocabulary;
}

class KanjiVocabularyGroups {
  const KanjiVocabularyGroups({
    required this.onyomi,
    required this.kunyomi,
    required this.unknown,
  });

  final List<KanjiVocabularyReadingGroup> onyomi;
  final List<KanjiVocabularyReadingGroup> kunyomi;
  final List<VocabularyEntry> unknown;

  int get onyomiCount => _uniqueCount(onyomi);
  int get kunyomiCount => _uniqueCount(kunyomi);

  static int _uniqueCount(List<KanjiVocabularyReadingGroup> groups) => groups
      .expand((group) => group.vocabulary)
      .map(vocabularyDisplayKey)
      .toSet()
      .length;
}

String vocabularyDisplayKey(VocabularyEntry vocab) => [
      vocab.kanji?.trim() ?? '',
      vocab.kana.trim(),
      vocab.meaning.trim(),
    ].join('\u0001');

/// Phân loại từ theo cách đọc chỉ khi mọi phép căn chỉnh hợp lệ đều thống nhất.
/// Các trường hợp bất quy tắc hoặc còn mơ hồ được giữ trong nhóm chưa xác định.
class KanjiVocabularyReadingClassifier {
  const KanjiVocabularyReadingClassifier();

  KanjiVocabularyGroups classify({
    required Kanji target,
    required Iterable<VocabularyEntry> vocabulary,
    required Map<String, Kanji> catalog,
  }) {
    final unique = <String, VocabularyEntry>{};
    final newestFirst = vocabulary.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final vocab in newestFirst) {
      unique.putIfAbsent(vocabularyDisplayKey(vocab), () => vocab);
    }

    final on = _emptyGroups(KanjiReadingType.on, target.onyomi);
    final kun = _emptyGroups(KanjiReadingType.kun, target.kunyomi);
    final unknown = <VocabularyEntry>[];
    final completeCatalog = {...catalog, target.character: target};

    for (final vocab in unique.values) {
      final matches = _classifyWord(
        target.character,
        vocab.kanji?.trim() ?? '',
        vocab.kana,
        completeCatalog,
      );
      if (matches == null || matches.isEmpty) {
        unknown.add(vocab);
        continue;
      }
      var added = false;
      for (final match in matches) {
        final destination = switch (match.type) {
          KanjiReadingType.on => on,
          KanjiReadingType.kun => kun,
          KanjiReadingType.unknown => null,
        };
        if (destination == null) continue;
        final group = destination[match.reading];
        if (group != null) {
          group.add(vocab);
          added = true;
        }
      }
      if (!added) unknown.add(vocab);
    }

    for (final words in [...on.values, ...kun.values, unknown]) {
      words.sort(_compareVocabulary);
    }
    return KanjiVocabularyGroups(
      onyomi: _toGroups(KanjiReadingType.on, target.onyomi, on),
      kunyomi: _toGroups(KanjiReadingType.kun, target.kunyomi, kun),
      unknown: List.unmodifiable(unknown),
    );
  }

  Map<String, List<VocabularyEntry>> _emptyGroups(
    KanjiReadingType type,
    Iterable<String> readings,
  ) {
    final result = <String, List<VocabularyEntry>>{};
    for (final reading in readings) {
      result.putIfAbsent(reading, () => <VocabularyEntry>[]);
    }
    return result;
  }

  List<KanjiVocabularyReadingGroup> _toGroups(
    KanjiReadingType type,
    Iterable<String> readings,
    Map<String, List<VocabularyEntry>> values,
  ) {
    final seen = <String>{};
    return [
      for (final reading in readings)
        if (seen.add(reading))
          KanjiVocabularyReadingGroup(
            type: type,
            reading: reading,
            vocabulary: List.unmodifiable(values[reading] ?? const []),
          ),
    ];
  }

  Set<_ReadingKey>? _classifyWord(
    String target,
    String written,
    String kana,
    Map<String, Kanji> catalog,
  ) {
    final normalizedKana = normalizeJapaneseReading(kana);
    final tokens = _tokens(written);
    if (normalizedKana.isEmpty || tokens.isEmpty) return null;

    var states = <(int, String)>{(0, '')};
    var overflowed = false;
    for (var tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
      final token = tokens[tokenIndex];
      final next = <(int, String)>{};
      if (token.catalogCharacter == null) {
        final literal = normalizeJapaneseReading(token.surface);
        for (final state in states) {
          if (normalizedKana.startsWith(literal, state.$1)) {
            next.add((state.$1 + literal.length, state.$2));
          }
        }
      } else {
        final kanji = catalog[token.catalogCharacter];
        if (kanji == null) return null;
        final candidates = _candidates(
          kanji,
          tokenIndex: tokenIndex,
          tokens: tokens,
        );
        for (final state in states) {
          for (final candidate in candidates) {
            for (final surface in candidate.surfaces) {
              if (!normalizedKana.startsWith(surface, state.$1)) continue;
              final signature = token.catalogCharacter == target
                  ? _addToSignature(state.$2, candidate.key)
                  : state.$2;
              next.add((state.$1 + surface.length, signature));
              if (next.length > 512) {
                overflowed = true;
                break;
              }
            }
            if (overflowed) break;
          }
          if (overflowed) break;
        }
      }
      if (overflowed || next.isEmpty) return null;
      states = next;
    }

    final signatures = states
        .where((state) => state.$1 == normalizedKana.length)
        .map((state) => state.$2)
        .where((signature) => signature.isNotEmpty)
        .toSet();
    if (signatures.length != 1) return null;
    return signatures.single.split('\u0002').map(_ReadingKey.decode).toSet();
  }

  List<_WrittenToken> _tokens(String written) {
    final result = <_WrittenToken>[];
    String? previousKanji;
    for (final rune in written.runes) {
      final char = String.fromCharCode(rune);
      if (isKanjiCodePoint(rune)) {
        previousKanji = char;
        result.add(_WrittenToken(char, char));
      } else if (char == '々' && previousKanji != null) {
        result.add(_WrittenToken(char, previousKanji));
      } else if (_isKana(rune) || char == 'ー') {
        result.add(_WrittenToken(char, null));
      } else if (char.trim().isNotEmpty && char != '・' && char != '･') {
        // Ký tự không thể đối chiếu làm cho toàn bộ từ trở nên không chắc chắn.
        return const [];
      }
    }
    return result;
  }

  List<_ReadingCandidate> _candidates(
    Kanji kanji, {
    required int tokenIndex,
    required List<_WrittenToken> tokens,
  }) =>
      [
        for (final reading in kanji.onyomi)
          if (_candidate(
            KanjiReadingType.on,
            reading,
            tokenIndex,
            tokens,
          )
              case final candidate?)
            candidate,
        for (final reading in kanji.kunyomi)
          if (_candidate(
            KanjiReadingType.kun,
            reading,
            tokenIndex,
            tokens,
          )
              case final candidate?)
            candidate,
      ];

  _ReadingCandidate? _candidate(
    KanjiReadingType type,
    String canonical,
    int tokenIndex,
    List<_WrittenToken> tokens,
  ) {
    var raw = canonical.trim();
    final requiresPrevious = raw.startsWith('-');
    final requiresFollowing = raw.endsWith('-');
    raw = raw.replaceAll('-', '');
    if (requiresPrevious && tokenIndex == 0) return null;
    if (requiresFollowing && tokenIndex == tokens.length - 1) return null;

    var consumed = raw;
    if (type == KanjiReadingType.kun && raw.contains('.')) {
      final dot = raw.indexOf('.');
      consumed = raw.substring(0, dot);
      final okurigana = normalizeJapaneseReading(raw.substring(dot + 1));
      if (okurigana.isNotEmpty &&
          !_followingLiteral(tokens, tokenIndex).startsWith(okurigana)) {
        return null;
      }
    }
    consumed = normalizeJapaneseReading(consumed.replaceAll('.', ''));
    if (consumed.isEmpty) return null;

    final surfaces = <String>{consumed};
    final hasPreviousWordPart = tokenIndex > 0;
    if (hasPreviousWordPart) {
      final voiced = _rendaku(consumed);
      if (voiced != null) surfaces.add(voiced);
    }
    if (_hasFollowingKanji(tokens, tokenIndex) &&
        (consumed.endsWith('く') || consumed.endsWith('つ'))) {
      surfaces.add('${consumed.substring(0, consumed.length - 1)}っ');
    }
    return _ReadingCandidate(
      _ReadingKey(type, canonical),
      surfaces.toList(growable: false),
    );
  }

  String _followingLiteral(List<_WrittenToken> tokens, int index) {
    final buffer = StringBuffer();
    for (var i = index + 1; i < tokens.length; i++) {
      if (tokens[i].catalogCharacter != null) break;
      buffer.write(tokens[i].surface);
    }
    return normalizeJapaneseReading(buffer.toString());
  }

  bool _hasFollowingKanji(List<_WrittenToken> tokens, int index) {
    for (var i = index + 1; i < tokens.length; i++) {
      if (tokens[i].catalogCharacter != null) return true;
      if (tokens[i].surface.trim().isNotEmpty) return false;
    }
    return false;
  }

  String? _rendaku(String reading) {
    const replacements = {
      'か': 'が',
      'き': 'ぎ',
      'く': 'ぐ',
      'け': 'げ',
      'こ': 'ご',
      'さ': 'ざ',
      'し': 'じ',
      'す': 'ず',
      'せ': 'ぜ',
      'そ': 'ぞ',
      'た': 'だ',
      'ち': 'ぢ',
      'つ': 'づ',
      'て': 'で',
      'と': 'ど',
      'は': 'ば',
      'ひ': 'び',
      'ふ': 'ぶ',
      'へ': 'べ',
      'ほ': 'ぼ',
    };
    for (final entry in replacements.entries) {
      if (reading.startsWith(entry.key)) {
        return '${entry.value}${reading.substring(entry.key.length)}';
      }
    }
    return null;
  }

  String _addToSignature(String signature, _ReadingKey key) {
    final keys =
        signature.isEmpty ? <String>{} : signature.split('\u0002').toSet();
    keys.add(key.encoded);
    final sorted = keys.toList()..sort();
    return sorted.join('\u0002');
  }
}

String normalizeJapaneseReading(String value) {
  final buffer = StringBuffer();
  for (final rune in value.trim().runes) {
    if (rune >= 0x30A1 && rune <= 0x30F6) {
      buffer.writeCharCode(rune - 0x60);
    } else {
      final char = String.fromCharCode(rune);
      if (char.trim().isNotEmpty) buffer.write(char);
    }
  }
  return buffer.toString();
}

bool _isKana(int rune) =>
    (rune >= 0x3041 && rune <= 0x309F) || (rune >= 0x30A0 && rune <= 0x30FF);

int _compareVocabulary(VocabularyEntry a, VocabularyEntry b) {
  final kana = normalizeJapaneseReading(a.kana)
      .compareTo(normalizeJapaneseReading(b.kana));
  if (kana != 0) return kana;
  final kanji = (a.kanji ?? '').trim().compareTo((b.kanji ?? '').trim());
  if (kanji != 0) return kanji;
  return a.meaning.trim().compareTo(b.meaning.trim());
}

class _WrittenToken {
  const _WrittenToken(this.surface, this.catalogCharacter);
  final String surface;
  final String? catalogCharacter;
}

class _ReadingKey {
  const _ReadingKey(this.type, this.reading);
  factory _ReadingKey.decode(String encoded) {
    final separator = encoded.indexOf('\u0001');
    return _ReadingKey(
      KanjiReadingType.values[int.parse(encoded.substring(0, separator))],
      encoded.substring(separator + 1),
    );
  }

  final KanjiReadingType type;
  final String reading;
  String get encoded => '${type.index}\u0001$reading';

  @override
  bool operator ==(Object other) =>
      other is _ReadingKey && other.type == type && other.reading == reading;

  @override
  int get hashCode => Object.hash(type, reading);
}

class _ReadingCandidate {
  const _ReadingCandidate(this.key, this.surfaces);
  final _ReadingKey key;
  final List<String> surfaces;
}
