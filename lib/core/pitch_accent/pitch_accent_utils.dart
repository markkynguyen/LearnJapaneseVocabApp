const _smallKana = {
  'ゃ',
  'ゅ',
  'ょ',
  'ぁ',
  'ぃ',
  'ぅ',
  'ぇ',
  'ぉ',
  'ゎ',
  'ャ',
  'ュ',
  'ョ',
  'ァ',
  'ィ',
  'ゥ',
  'ェ',
  'ォ',
  'ヮ',
};

List<String> splitKanaMora(String kana) {
  final units = <String>[];
  for (final rune in kana.trim().runes) {
    final char = String.fromCharCode(rune);
    if (_smallKana.contains(char) && units.isNotEmpty) {
      units[units.length - 1] = '${units.last}$char';
    } else if (char.trim().isNotEmpty) {
      units.add(char);
    }
  }
  return units;
}

String defaultPitchPattern(String kana) {
  return 'L' * splitKanaMora(kana).length;
}

String? normalizePitchPattern(String? pattern, String kana) {
  final trimmed = pattern?.trim().toUpperCase();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  final moraCount = splitKanaMora(kana).length;
  if (trimmed.length != moraCount) {
    return null;
  }
  return RegExp(r'^[LH]+$').hasMatch(trimmed) ? trimmed : null;
}

String resizePitchPattern(String? pattern, String kana) {
  final moraCount = splitKanaMora(kana).length;
  if (moraCount == 0) {
    return '';
  }

  final source = pattern?.trim().toUpperCase() ?? '';
  final buffer = StringBuffer();
  for (var i = 0; i < moraCount; i++) {
    final char = i < source.length ? source[i] : 'L';
    buffer.write(char == 'H' ? 'H' : 'L');
  }
  return buffer.toString();
}

bool isValidPitchPattern(String? pattern, String kana) {
  return normalizePitchPattern(pattern, kana) != null;
}
