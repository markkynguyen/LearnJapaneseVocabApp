import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/features/kanji/domain/kanji_models.dart';
import 'package:jvocab/features/kanji/presentation/radical_display_groups.dart';

RadicalForm _form({
  required int radicalId,
  required String character,
  required String form,
  required int count,
  int formOrder = 0,
}) =>
    RadicalForm(
      radical: Radical(
        id: radicalId,
        character: character,
        nameVi: 'Tên $character',
        meaningVi: 'Nghĩa $character',
        strokeCount: 1,
      ),
      form: form,
      count: count,
      familyCount: count,
      isOriginal: form == character,
      formOrder: formOrder,
    );

void main() {
  test('gộp đúng bốn nhóm đã chọn và giữ dạng gốc độc lập', () {
    final items = radicalDisplayItems([
      _form(radicalId: 87, character: '爪', form: '爪', count: 7),
      _form(radicalId: 87, character: '爪', form: '爫', count: 3, formOrder: 1),
      _form(radicalId: 87, character: '爪', form: '⺤', count: 2, formOrder: 2),
      _form(radicalId: 90, character: '爿', form: '丬', count: 4, formOrder: 1),
      _form(radicalId: 90, character: '爿', form: '⺦', count: 6, formOrder: 2),
      _form(radicalId: 94, character: '犬', form: '犭', count: 8, formOrder: 1),
      _form(radicalId: 94, character: '犬', form: '⺨', count: 1, formOrder: 2),
      _form(radicalId: 162, character: '辵', form: '辶', count: 2, formOrder: 1),
      _form(radicalId: 162, character: '辵', form: '辶', count: 3, formOrder: 2),
      _form(radicalId: 162, character: '辵', form: '⻌', count: 4, formOrder: 3),
    ]);

    expect(
      items.map((item) => item.form),
      containsAll(['爪', '爫', '丬', '犭', '辶']),
    );
    expect(items, hasLength(5));
    expect(items.singleWhere((item) => item.form == '爪').count, 7);
    expect(items.singleWhere((item) => item.form == '爫').count, 5);
    expect(items.singleWhere((item) => item.form == '丬').count, 10);
    expect(items.singleWhere((item) => item.form == '犭').count, 9);
    expect(items.singleWhere((item) => item.form == '辶').count, 9);
    expect(
      items.singleWhere((item) => item.form == '辶').memberForms,
      ['辶', '辶', '⻌'],
    );
  });

  test('chỉ gộp dạng có mặt và không ảnh hưởng biến thể khác', () {
    final items = radicalDisplayItems([
      _form(radicalId: 87, character: '爪', form: '⺤', count: 4, formOrder: 2),
      _form(radicalId: 9, character: '人', form: '亻', count: 9, formOrder: 1),
      _form(radicalId: 9, character: '人', form: '𠆢', count: 0, formOrder: 2),
    ]);

    expect(items.map((item) => item.form), ['亻', '爫']);
    final grouped = items.singleWhere((item) => item.form == '爫');
    expect(grouped.count, 4);
    expect(grouped.isGrouped, isTrue);
    expect(items.singleWhere((item) => item.form == '亻').isGrouped, isFalse);
  });
}
