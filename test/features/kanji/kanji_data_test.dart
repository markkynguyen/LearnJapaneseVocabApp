import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/kanji/data/kanji_repository.dart';
import 'package:jvocab/features/kanji/domain/kanji_models.dart';
import 'package:jvocab/features/kanji/presentation/providers/kanji_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'fixtures.dart';

class FakeKanjiStore extends CloudStore {
  FakeKanjiStore()
      : super(
          SupabaseClient(
            'https://example.supabase.co',
            'test',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );
  int reads = 0, recalculations = 0;
  Object? error;
  Completer<void>? pending;
  Map<String, dynamic> data = snapshotJson();
  List<VocabularyEntry> vocabulary = const [];
  Map<String, Set<int>> radicalKanjiIds = const {};
  @override
  Future<Map<String, dynamic>> getKanjiSnapshot() async {
    reads++;
    if (error != null) throw error!;
    return data;
  }

  @override
  Future<void> recalculateKanjiStats() async {
    recalculations++;
    if (pending != null) await pending!.future;
    if (error != null) throw error!;
  }

  @override
  Future<Map<String, dynamic>?> getKanji(String character) async {
    if (error != null) throw error!;
    return kanjiJson(character);
  }

  @override
  Future<Map<String, dynamic>?> getKanjiDecomposition(int id) async {
    if (error != null) throw error!;
    return null;
  }

  @override
  Future<List<VocabularyEntry>> getVocabContainingKanji(
    String character, {
    int pageSize = 500,
  }) async {
    if (error != null) throw error!;
    return vocabulary
        .where((vocab) => vocab.kanji?.contains(character) ?? false)
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getKanjiByCharacters(
    Iterable<String> characters,
  ) async {
    if (error != null) throw error!;
    return characters.map(kanjiJson).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getKanjiComponentOccurrences(
    int id,
  ) async {
    if (error != null) throw error!;
    return [occurrenceJson()];
  }

  @override
  Future<Set<int>> getKanjiIdsForRadicalForm(
    int radicalId,
    String form,
  ) async {
    if (error != null) throw error!;
    final configured = radicalKanjiIds[form];
    if (configured != null) return configured;
    return form == '亻' ? {'休'.runes.single} : {'先'.runes.single};
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
      'extracts scalar CJK characters in order, preserves repetition, skips selectors/kana',
      () {
    expect(
      extractKanjiCharacters('先先生・食べる𠮟𠮷々\u{E0100}🙂'),
      ['先', '先', '生', '食', '𠮟', '𠮷'],
    );
    expect(extractKanjiCharacters(null), isEmpty);
    expect(extractKanjiCharacters('かな カナ 123'), isEmpty);
    expect(extractKanjiCharacters(String.fromCharCode(0x323B0)), hasLength(1));
  });
  test(
      'parses high counts, secondary grade, nullable translation and timestamp zone',
      () {
    final kanji = Kanji.fromJson({
      ...kanjiJson('休'),
      'grade': 8,
      'meaning_vi': null,
      'count': 5000000000,
    });
    expect(kanji.gradeLabel, 'Trung học');
    expect(kanji.count, 5000000000);
    expect(kanji.meaningVi, isNull);
    expect(
      KanjiSnapshot.fromJson(snapshotJson()).overview!.calculatedAt.isUtc,
      isTrue,
    );
  });
  test('parses separate radical forms and falls back to legacy snapshots', () {
    final snapshot = KanjiSnapshot.fromJson(snapshotJson());
    expect(
      snapshot.radicalForms.map((item) => item.form),
      ['人', '亻', '𠆢', '入'],
    );
    expect(snapshot.radicalForms.map((item) => item.count), [8, 12, 0, 0]);
    expect(
      snapshot.radicalForms.map((item) => item.familyCount),
      [20, 20, 20, 20],
    );
    expect(snapshot.radicalForms.map((item) => item.radical.nameVi).toSet(), {
      'Nhân',
    });

    final legacyJson = snapshotJson()..remove('radical_forms');
    final legacy = KanjiSnapshot.fromJson(legacyJson);
    expect(legacy.radicalForms, hasLength(1));
    expect(legacy.radicalForms.single.form, '人');
    expect(legacy.radicalForms.single.count, 20);
  });
  test(
      'does not calculate on provider reads; coalesces repeated button presses',
      () async {
    final store = FakeKanjiStore()..pending = Completer();
    final container = ProviderContainer(
      overrides: [
        kanjiRepositoryProvider.overrideWithValue(KanjiRepository(store, 'u1')),
      ],
    );
    addTearDown(container.dispose);
    await container.read(kanjiSnapshotProvider.future);
    await container.read(kanjiRefreshProvider.future);
    expect(store.recalculations, 0);
    final controller = container.read(kanjiRefreshProvider.notifier);
    final first = controller.refresh();
    await controller.refresh();
    expect(store.recalculations, 1);
    store.pending!.complete();
    await first;
    expect(store.reads, 2);
    expect(container.read(kanjiRefreshProvider).hasError, isFalse);
  });
  test('RPC error retains existing snapshot and allows retry', () async {
    final store = FakeKanjiStore();
    final container = ProviderContainer(
      overrides: [
        kanjiRepositoryProvider.overrideWithValue(KanjiRepository(store, 'u1')),
      ],
    );
    addTearDown(container.dispose);
    final old = await container.read(kanjiSnapshotProvider.future);
    await container.read(kanjiRefreshProvider.future);
    store.error = const PostgrestException(message: 'denied');
    await container.read(kanjiRefreshProvider.notifier).refresh();
    expect(container.read(kanjiRefreshProvider).hasError, isTrue);
    expect(container.read(kanjiSnapshotProvider).value, same(old));
    store.error = null;
    await container.read(kanjiRefreshProvider.notifier).refresh();
    expect(container.read(kanjiRefreshProvider).hasError, isFalse);
  });
  test(
      'persistent offline snapshots are isolated by account and details reopen',
      () async {
    final store = FakeKanjiStore();
    final online = KanjiRepository(store, 'alice');
    await online.loadSnapshot();
    await online.getKanji('休');
    await online.getOccurrences('休'.runes.single);
    await online.getKanjiIdsForRadicalForm(9, '人');
    await online.getKanjiIdsForRadicalForm(9, '亻');
    final offline = KanjiRepository(store, 'alice', isOffline: () => true);
    expect((await offline.loadSnapshot()).fromCache, isTrue);
    expect((await offline.getKanji('休'))!.meaningVi, 'Nghỉ ngơi');
    expect(
      (await offline.getOccurrences('休'.runes.single)).single.strokeIds,
      ['s1', 's2'],
    );
    expect(await offline.getKanjiIdsForRadicalForm(9, '人'), {
      '先'.runes.single,
    });
    expect(await offline.getKanjiIdsForRadicalForm(9, '亻'), {
      '休'.runes.single,
    });
    await expectLater(
      KanjiRepository(store, 'bob', isOffline: () => true).loadSnapshot(),
      throwsStateError,
    );
    store.error = const PostgrestException(message: 'denied');
    await expectLater(
      online.loadSnapshot(),
      throwsA(isA<PostgrestException>()),
    );
    store.error = http.ClientException('network down');
    expect((await online.loadSnapshot()).fromCache, isTrue);
  });
  test('corrupt persistent cache is rejected', () async {
    SharedPreferences.setMockInitialValues({'kanji.snapshot.v4.a': 'not JSON'});
    await expectLater(
      KanjiRepository(FakeKanjiStore(), 'a', isOffline: () => true)
          .loadSnapshot(),
      throwsStateError,
    );
  });
  test('old snapshot keeps counts and requests manual component update', () {
    final raw = snapshotJson();
    (raw['overview'] as Map).remove('component_version');
    final old = KanjiSnapshot.fromJson(raw);
    expect(old.overview!.needsComponentUpdate, isTrue);
    expect(old.kanji.first.count, 12);
  });
  test('v4 ignores every previous snapshot cache namespace offline', () async {
    SharedPreferences.setMockInitialValues({
      'kanji.snapshot.v1.a': jsonEncode(snapshotJson()),
      'kanji.snapshot.v3.a': jsonEncode(snapshotJson()),
      'kanji.catalog.v2.char.休': jsonEncode(kanjiJson('休')),
      'kanji.catalog.v2.occurrences.20241': jsonEncode([occurrenceJson()]),
      'kanji.tree.v1.root.20241': '{}',
    });
    final repository =
        KanjiRepository(FakeKanjiStore(), 'a', isOffline: () => true);
    await expectLater(repository.loadSnapshot(), throwsStateError);
    await expectLater(repository.getKanji('休'), throwsStateError);
    await expectLater(
      repository.getOccurrences('休'.runes.single),
      throwsStateError,
    );
    await expectLater(
      repository.getKanjiDecomposition('休'.runes.single),
      throwsStateError,
    );
    final v2 = snapshotJson();
    (v2['overview'] as Map)['component_version'] = 2;
    expect(KanjiSnapshot.fromJson(v2).overview!.needsComponentUpdate, isTrue);
    expect(
      KanjiSnapshot.fromJson(snapshotJson()).overview!.needsComponentUpdate,
      isFalse,
    );
  });
}
