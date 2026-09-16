import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cloud/cloud_store.dart';
import '../domain/kanji_vocabulary_readings.dart';
import '../domain/kanji_models.dart';
import '../domain/kanji_decomposition.dart';

class KanjiRepository {
  KanjiRepository(this.store, this.userId, {bool Function()? isOffline})
      : _isOffline = isOffline ?? (() => false);
  final CloudStore store;
  final String userId;
  final bool Function() _isOffline;
  static const _catalogPrefix = 'kanji.catalog.v3.';
  static const _treePrefix = 'kanji.tree.v2.';
  Future<void> _writes = Future.value();

  Future<({dynamic json, bool cached})> _load(
    String key,
    Future<dynamic> Function() request,
  ) async {
    Object? networkError;
    if (!_isOffline()) {
      try {
        final json = await request().timeout(const Duration(seconds: 15));
        try {
          await _save(key, jsonEncode(json));
        } catch (_) {}
        return (json: json, cached: false);
      } on http.ClientException catch (error) {
        networkError = error;
      } on TimeoutException catch (error) {
        networkError = error;
      }
      // Auth, RLS and schema errors must never be masked by old data.
    }
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw != null) {
      try {
        return (json: jsonDecode(raw), cached: true);
      } on FormatException {
        await (await SharedPreferences.getInstance()).remove(key);
      }
    }
    throw networkError ??
        StateError(
          'Nội dung này chưa được lưu. Hãy kết nối Internet để tải lần đầu.',
        );
  }

  Future<void> _save(String key, String raw) {
    final operation = _writes.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, raw);
      final prefix = key.startsWith(_treePrefix) ? _treePrefix : _catalogPrefix;
      if (!key.startsWith(prefix)) return;
      final order = prefs.getStringList('${prefix}order') ?? [];
      order.remove(key);
      order.add(key);
      var bytes = order.fold<int>(
        0,
        (sum, k) => sum + (prefs.getString(k)?.length ?? 0) * 2,
      );
      while ((bytes > 1024 * 1024 || order.length > 200) && order.length > 1) {
        final oldest = order.removeAt(0);
        bytes -= (prefs.getString(oldest)?.length ?? 0) * 2;
        await prefs.remove(oldest);
      }
      await prefs.setStringList('${prefix}order', order);
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<KanjiSnapshot> loadSnapshot() async {
    final result =
        await _load('kanji.snapshot.v4.$userId', store.getKanjiSnapshot);
    return KanjiSnapshot.fromJson(
      Map<String, dynamic>.from(result.json as Map),
      fromCache: result.cached,
    );
  }

  Future<void> recalculate() => store.recalculateKanjiStats();

  Future<KanjiDecomposition?> getKanjiDecomposition(int id) async {
    final result = await _load(
      '${_treePrefix}root.$id',
      () => store.getKanjiDecomposition(id),
    );
    if (result.json == null) return null;
    final tree = KanjiDecomposition.fromJson(
      Map<String, dynamic>.from(result.json as Map),
    );
    if (tree.kanjiId != id || tree.root.form != String.fromCharCode(id)) {
      throw const FormatException('Cây không thuộc Hán tự đang xem.');
    }
    return tree;
  }

  Future<Map<String, Kanji>> getDecompositionMeanings(
    KanjiDecomposition tree,
  ) async {
    final characters = tree.root.descendants
        .where((n) => n.kind == KanjiComponentKind.kanji)
        .map((n) => n.form)
        .whereType<String>()
        .toSet();
    if (characters.isEmpty) return {};
    final result = await _load(
      '${_treePrefix}meanings.${tree.kanjivgCommit}.${tree.kanjiId}',
      () => store.getKanjiByCharacters(characters),
    );
    return {
      for (final row in result.json as List)
        (row as Map)['character'] as String:
            Kanji.fromJson(Map<String, dynamic>.from(row)),
    };
  }

  Future<Kanji?> getKanji(String character) async {
    final result = await _load(
      '${_catalogPrefix}char.$character',
      () => store.getKanji(character),
    );
    return result.json == null
        ? null
        : Kanji.fromJson(Map<String, dynamic>.from(result.json as Map));
  }

  Future<KanjiVocabularyGroups> getVocabularyGroups(Kanji target) async {
    final vocabulary = await store.getVocabContainingKanji(target.character);
    final characters = vocabulary
        .expand((vocab) => extractKanjiCharacters(vocab.kanji))
        .toSet();
    final rows = await store.getKanjiByCharacters(characters);
    final catalog = {
      for (final row in rows)
        if (row['character'] case final String character)
          character: Kanji.fromJson(Map<String, dynamic>.from(row)),
    };
    return const KanjiVocabularyReadingClassifier().classify(
      target: target,
      vocabulary: vocabulary,
      catalog: catalog,
    );
  }

  Future<List<KanjiComponent>> getComponents(int id) async {
    final result = await _load(
      '${_catalogPrefix}components.$id',
      () => store.getKanjiComponents(id),
    );
    return (result.json as List)
        .map(
          (row) =>
              KanjiComponent.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<Set<int>> getKanjiIdsForRadicalForm(int id, String form) async {
    final result = await _load(
      '${_catalogPrefix}related.$id.$form',
      () async => (await store.getKanjiIdsForRadicalForm(id, form)).toList(),
    );
    return (result.json as List).map((id) => (id as num).toInt()).toSet();
  }

  /// Hợp nhất các Hán tự chứa bất kỳ dạng nào của cùng một bộ thủ.
  ///
  /// Việc gộp chỉ phục vụ UI; catalog và RPC vẫn truy vấn từng dạng gốc.
  Future<Set<int>> getKanjiIdsForRadicalForms(
    int id,
    Iterable<String> forms,
  ) async {
    final ids = await Future.wait(
      forms.toSet().map((form) => getKanjiIdsForRadicalForm(id, form)),
    );
    return ids.expand((items) => items).toSet();
  }

  Future<List<KanjiComponentOccurrence>> getOccurrences(int id) async {
    final result = await _load(
      '${_catalogPrefix}occurrences.$id',
      () => store.getKanjiComponentOccurrences(id),
    );
    final rows = result.json as List;
    if (rows.any((row) => (row as Map)['component_version'] != 3)) {
      throw const FormatException('Dữ liệu thành phần cần được cập nhật.');
    }
    return rows
        .map(
          (row) => KanjiComponentOccurrence.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }
}
