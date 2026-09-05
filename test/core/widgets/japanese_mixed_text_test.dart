import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/core/theme/app_theme.dart';
import 'package:jvocab/core/widgets/japanese_mixed_text.dart';

void main() {
  testWidgets('only Japanese runs use the selected Japanese font',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(
          japaneseFont: JapaneseFontChoice.clearModern,
        ),
        home: const Scaffold(body: JapaneseMixedText('Ví dụ: 先生')),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    final spans = (text.textSpan! as TextSpan).children!.cast<TextSpan>();
    final japanese = spans.singleWhere((span) => span.text == '先生');
    final vietnamese = spans.singleWhere((span) => span.text == 'Ví dụ: ');

    expect(japanese.style?.fontFamily, 'BizUDPGothic');
    expect(vietnamese.style, isNull);
  });
}
