import '../domain/kanji_models.dart';

/// Một mục bộ thủ được tính riêng cho mục đích hiển thị.
///
/// Một vài dạng thành phần gần như giống nhau được gộp trên UI, nhưng catalog
/// và thống kê gốc từ Supabase vẫn được giữ nguyên.
class RadicalDisplayItem {
  const RadicalDisplayItem({
    required this.radicalForm,
    required this.count,
    required this.memberForms,
    required this.isGrouped,
  });

  final RadicalForm radicalForm;
  final int count;
  final List<String> memberForms;
  final bool isGrouped;

  String get form => radicalForm.form;
  Radical get radical => radicalForm.radical;
}

class _RadicalFormGroup {
  const _RadicalFormGroup({
    required this.radicalId,
    required this.representative,
    required this.members,
  });

  final int radicalId;
  final String representative;
  final List<String> members;

  bool contains(RadicalForm form) =>
      form.radical.id == radicalId && members.contains(form.form);
}

const _radicalFormGroups = [
  _RadicalFormGroup(
    radicalId: 87,
    representative: '爫',
    members: ['爫', '⺤'],
  ),
  _RadicalFormGroup(
    radicalId: 90,
    representative: '丬',
    members: ['丬', '⺦'],
  ),
  _RadicalFormGroup(
    radicalId: 94,
    representative: '犭',
    members: ['犭', '⺨'],
  ),
  _RadicalFormGroup(
    radicalId: 162,
    representative: '辶',
    members: ['辶', '辶', '⻌'],
  ),
];

_RadicalFormGroup? _groupFor(RadicalForm form) {
  for (final group in _radicalFormGroups) {
    if (group.contains(form)) return group;
  }
  return null;
}

/// Trả về một mục hiển thị cho một dạng riêng lẻ.
///
/// Dùng khi điều hướng từ chi tiết bộ thủ gốc sang một dạng nằm trong nhóm.
/// Số lượng gộp đầy đủ được tính khi xây dựng danh sách từ snapshot.
RadicalDisplayItem radicalDisplayItemForForm(RadicalForm form) {
  final group = _groupFor(form);
  if (group == null) {
    return RadicalDisplayItem(
      radicalForm: form,
      count: form.count,
      memberForms: [form.form],
      isGrouped: false,
    );
  }
  return RadicalDisplayItem(
    radicalForm: _representativeForm(group, [form], form.count),
    count: form.count,
    memberForms: group.members,
    isGrouped: true,
  );
}

/// Gộp bốn nhóm dạng bộ thủ đã được chốt cho UI.
///
/// Các dạng gốc và toàn bộ biến thể khác vẫn là các mục độc lập. Dạng có số
/// lượt bằng 0 không xuất hiện trong danh sách, đúng với hành vi hiện tại.
List<RadicalDisplayItem> radicalDisplayItems(Iterable<RadicalForm> forms) {
  final grouped = <_RadicalFormGroup, List<RadicalForm>>{};
  final result = <RadicalDisplayItem>[];

  for (final form in forms) {
    if (form.count <= 0) continue;
    final group = _groupFor(form);
    if (group == null) {
      result.add(
        RadicalDisplayItem(
          radicalForm: form,
          count: form.count,
          memberForms: [form.form],
          isGrouped: false,
        ),
      );
    } else {
      (grouped[group] ??= []).add(form);
    }
  }

  for (final entry in grouped.entries) {
    final members = entry.value;
    final count = members.fold<int>(0, (sum, form) => sum + form.count);
    result.add(
      RadicalDisplayItem(
        radicalForm: _representativeForm(entry.key, members, count),
        count: count,
        memberForms: entry.key.members,
        isGrouped: true,
      ),
    );
  }

  result.sort(compareRadicalDisplayItems);
  return result;
}

RadicalForm _representativeForm(
  _RadicalFormGroup group,
  List<RadicalForm> members,
  int count,
) {
  final source = members.first;
  final formOrder = members
      .map((item) => item.formOrder)
      .reduce((value, item) => value < item ? value : item);
  return RadicalForm(
    radical: source.radical,
    form: group.representative,
    count: count,
    familyCount: source.familyCount,
    isOriginal: false,
    formOrder: formOrder,
  );
}

int compareRadicalDisplayItems(RadicalDisplayItem a, RadicalDisplayItem b) {
  final countOrder = b.count.compareTo(a.count);
  if (countOrder != 0) return countOrder;
  final radicalOrder = a.radical.id.compareTo(b.radical.id);
  if (radicalOrder != 0) return radicalOrder;
  return a.radicalForm.formOrder.compareTo(b.radicalForm.formOrder);
}
