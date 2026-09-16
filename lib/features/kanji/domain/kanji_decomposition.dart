import 'kanji_models.dart';
export 'kanji_models.dart' show KanjiComponentKind;

class KanjiDecompositionNode {
  const KanjiDecompositionNode({
    required this.id,
    required this.kind,
    required this.strokeIds,
    this.form,
    this.sourceElement,
    this.sourceOriginal,
    this.radicalName,
    this.radicalId,
    this.radicalMeaning,
    this.radical,
    this.sourcePartial = false,
    this.groupIds = const [],
    this.children = const [],
  });

  factory KanjiDecompositionNode.fromJson(Map<String, dynamic> json) =>
      KanjiDecompositionNode(
        id: json['id'] as String,
        kind: KanjiComponentKind.values.byName(json['kind'] as String),
        form: json['display_form'] as String?,
        sourceElement: json['source_element'] as String?,
        sourceOriginal: json['source_original'] as String?,
        radicalName: json['radical_name'] as String?,
        radicalId: (json['radical_id'] as num?)?.toInt(),
        radicalMeaning: json['radical_meaning'] as String?,
        radical: json['radical'] == null
            ? null
            : Radical.fromJson(
                Map<String, dynamic>.from(json['radical'] as Map),
              ),
        sourcePartial: json['source_partial'] == true,
        groupIds: List<String>.from(json['source_group_ids'] as List),
        strokeIds: List<String>.from(json['stroke_ids'] as List),
        children: (json['children'] as List)
            .map(
              (c) => KanjiDecompositionNode.fromJson(
                Map<String, dynamic>.from(c as Map),
              ),
            )
            .toList(growable: false),
      );

  final String id;
  final KanjiComponentKind kind;
  final String? form, sourceElement, sourceOriginal, radicalName;
  final int? radicalId;
  final String? radicalMeaning;
  final bool sourcePartial;
  final Radical? radical;

  RadicalForm? get radicalForm => radical == null || form == null
      ? null
      : RadicalForm(
          radical: radical!,
          form: form!,
          count: 0,
          familyCount: 0,
          isOriginal: form == radical!.character,
          formOrder: 0,
        );
  final List<String> strokeIds, groupIds;
  final List<KanjiDecompositionNode> children;

  String get typeLabel => switch (kind) {
        KanjiComponentKind.kanji => 'Hán tự',
        KanjiComponentKind.radical => 'Bộ thủ',
        KanjiComponentKind.supplementary => 'Nét phụ',
      };
  String get label => kind == KanjiComponentKind.supplementary
      ? typeLabel
      : [form, radicalName].whereType<String>().join(' ').trim();

  Iterable<KanjiDecompositionNode> get descendants sync* {
    yield this;
    for (final child in children) {
      yield* child.descendants;
    }
  }

  KanjiComponentOccurrence asOccurrence(String commit) =>
      KanjiComponentOccurrence(
        id: id,
        form: form,
        sourceElement: sourceElement,
        sourceOriginal: sourceOriginal,
        kind: kind,
        radicalId: radicalId,
        sourcePartial: sourcePartial,
        groupIds: groupIds,
        strokeIds: strokeIds,
        sortOrder: 0,
        kanjivgCommit: commit,
      );
}

class KanjiDecomposition {
  KanjiDecomposition({
    required this.kanjiId,
    required this.structureVersion,
    required this.kanjivgCommit,
    required this.root,
  }) {
    if (structureVersion != 2) {
      throw const FormatException('Phiên bản cây chưa được hỗ trợ.');
    }
    final seen = <String>{};
    void validate(KanjiDecompositionNode node) {
      if (node.kind == KanjiComponentKind.radical
          ? node.radicalId == null ||
              node.radicalId! < 1 ||
              node.radicalId! > 214 ||
              node.children.isNotEmpty
          : node.radicalId != null ||
              (node.kind == KanjiComponentKind.supplementary &&
                  node.children.isNotEmpty)) {
        throw const FormatException('Phân loại thành phần không hợp lệ.');
      }
      if (node.id.isEmpty ||
          !seen.add(node.id) ||
          node.strokeIds.isEmpty ||
          node.strokeIds.toSet().length != node.strokeIds.length) {
        throw const FormatException('Thành phần không hợp lệ.');
      }
      if (node.children.isNotEmpty) {
        final strokes = node.children.expand((n) => n.strokeIds).toList();
        if (strokes.length != node.strokeIds.length ||
            strokes.toSet().length != strokes.length ||
            !strokes.toSet().containsAll(node.strokeIds)) {
          throw const FormatException('Các thành phần không phủ đúng nét cha.');
        }
      }
      for (final child in node.children) {
        validate(child);
      }
    }

    validate(root);
  }

  factory KanjiDecomposition.fromJson(Map<String, dynamic> json) =>
      KanjiDecomposition(
        kanjiId: (json['kanji_id'] as num).toInt(),
        structureVersion: (json['structure_version'] as num).toInt(),
        kanjivgCommit: json['kanjivg_commit'] as String,
        root: KanjiDecompositionNode.fromJson(
          Map<String, dynamic>.from(json['tree'] as Map),
        ),
      );

  final int kanjiId, structureVersion;
  final String kanjivgCommit;
  final KanjiDecompositionNode root;
}

/// Lựa chọn theo lần xuất hiện trong chữ gốc, không theo ký tự trùng nhau.
class KanjiDecompositionSelection {
  final List<KanjiDecompositionNode> branch = [];
  KanjiDecompositionNode? selected;

  void select(KanjiDecompositionNode node, int depth) {
    final deselect = selected?.id == node.id;
    if (branch.length > depth) branch.removeRange(depth, branch.length);
    selected = deselect ? null : node;
    if (!deselect && node.children.isNotEmpty) branch.add(node);
  }

  void clear() {
    branch.clear();
    selected = null;
  }
}
