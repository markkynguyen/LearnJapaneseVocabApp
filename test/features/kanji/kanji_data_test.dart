import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:jvocab/core/cloud/cloud_store.dart';
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
    final offline = KanjiRepository(store, 'alice', isOffline: () => true);
    expect((await offline.loadSnapshot()).fromCache, isTrue);
    expect((await offline.getKanji('休'))!.meaningVi, 'Nghỉ ngơi');
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
    SharedPreferences.setMockInitialValues({'kanji.snapshot.v1.a': 'not JSON'});
    await expectLater(
      KanjiRepository(FakeKanjiStore(), 'a', isOffline: () => true)
          .loadSnapshot(),
      throwsStateError,
    );
  });
}
