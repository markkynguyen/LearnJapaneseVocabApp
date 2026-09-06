import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cloud/cloud_store.dart';
import '../domain/kanji_vocabulary_readings.dart';
import '../domain/kanji_models.dart';

class KanjiRepository {
  KanjiRepository(this.store, this.userId, {bool Function()? isOffline})
      : _isOffline = isOffline ?? (() => false);
  final CloudStore store;
  final String userId;
  final bool Function() _isOffline;
  static const _catalogPrefix = 'kanji.catalog.v2.';
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
      if (!key.startsWith(_catalogPrefix)) return;
      final order = prefs.getStringList('${_catalogPrefix}order') ?? [];
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
      await prefs.setStringList('${_catalogPrefix}order', order);
    });
    _writes = operation.catchError((Object _) {});
    return operation;
  }

  Future<KanjiSnapshot> loadSnapshot() async {
    final result =
        await _load('kanji.snapshot.v1.$userId', store.getKanjiSnapshot);
    return KanjiSnapshot.fromJson(
      Map<String, dynamic>.from(result.json as Map),
      fromCache: result.cached,
    );
  }

  Future<void> recalculate() => store.recalculateKanjiStats();

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

  Future<List<KanjiComponentOccurrence>> getOccurrences(int id) async {
    final result = await _load(
      '${_catalogPrefix}occurrences.$id',
      () => store.getKanjiComponentOccurrences(id),
    );
    return (result.json as List)
        .map(
          (row) => KanjiComponentOccurrence.fromJson(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList();
  }
}
