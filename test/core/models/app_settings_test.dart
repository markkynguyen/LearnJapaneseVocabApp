import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/models/app_models.dart';

void main() {
  test('Japanese font defaults to Klee One and parses persisted choices', () {
    expect(const AppSettings().japaneseFont, JapaneseFontChoice.textbook);
    expect(
      AppSettings.fromCloud(const {}, const {'japanese_font': 'biz_udpgothic'})
          .japaneseFont,
      JapaneseFontChoice.clearModern,
    );
    expect(
      AppSettings.fromCloud(const {}, const {'japanese_font': 'unknown'})
          .japaneseFont,
      JapaneseFontChoice.textbook,
    );
  });

  test('copyWith retains the selected Japanese font', () {
    final settings = const AppSettings().copyWith(
      japaneseFont: JapaneseFontChoice.clearModern,
    );

    expect(settings.japaneseFont.storageValue, 'biz_udpgothic');
  });
}
