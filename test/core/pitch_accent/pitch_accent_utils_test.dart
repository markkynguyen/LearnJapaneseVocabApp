import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/pitch_accent/pitch_accent_utils.dart';

void main() {
  group('splitKanaMora', () {
    test('splits plain kana into mora units', () {
      expect(splitKanaMora('たまご'), ['た', 'ま', 'ご']);
      expect(splitKanaMora('ありがとう'), ['あ', 'り', 'が', 'と', 'う']);
    });

    test('keeps small kana with the previous mora', () {
      expect(splitKanaMora('きょう'), ['きょ', 'う']);
      expect(splitKanaMora('しゃしん'), ['しゃ', 'し', 'ん']);
    });

    test('keeps sokuon, nasal n, and long vowel mark selectable', () {
      expect(splitKanaMora('がっこう'), ['が', 'っ', 'こ', 'う']);
      expect(splitKanaMora('スーパー'), ['ス', 'ー', 'パ', 'ー']);
    });
  });

  group('pitch pattern', () {
    test('normalizes valid L/H pattern', () {
      expect(normalizePitchPattern('lhl', 'たまご'), 'LHL');
    });

    test('rejects invalid pattern or mismatched mora length', () {
      expect(normalizePitchPattern('LH', 'たまご'), isNull);
      expect(normalizePitchPattern('LHX', 'たまご'), isNull);
    });

    test('resizes pattern while preserving existing high selections', () {
      expect(resizePitchPattern('LH', 'たまご'), 'LHL');
      expect(resizePitchPattern('LHHH', 'きょう'), 'LH');
      expect(resizePitchPattern(null, 'がっこう'), 'LLLL');
    });
  });
}
