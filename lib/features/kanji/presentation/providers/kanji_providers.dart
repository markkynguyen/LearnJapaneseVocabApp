import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cloud/cloud_store.dart';
import '../../../../core/connectivity/cloud_connectivity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/kanji_repository.dart';
import '../../domain/kanji_models.dart';
import '../../domain/kanji_decomposition.dart';
import '../../domain/kanji_vocabulary_readings.dart';

final kanjiRepositoryProvider = Provider<KanjiRepository>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) throw StateError('Bạn chưa đăng nhập.');
  return KanjiRepository(
    ref.watch(cloudStoreProvider),
    session.user.id,
    isOffline: () => ref.read(hasNetworkProvider).valueOrNull == false,
  );
});

// Chỉ đọc snapshot; không tự tính lại khi mở màn hình hay sửa từ vựng.
final kanjiSnapshotProvider = FutureProvider<KanjiSnapshot>(
  (ref) => ref.watch(kanjiRepositoryProvider).loadSnapshot(),
);
final kanjiDetailProvider = FutureProvider.family<Kanji?, String>(
  (ref, char) => ref.watch(kanjiRepositoryProvider).getKanji(char),
);
final kanjiVocabularyGroupsProvider =
    FutureProvider.autoDispose.family<KanjiVocabularyGroups, String>(
  (ref, char) async {
    final repository = ref.watch(kanjiRepositoryProvider);
    final kanji = await ref.watch(kanjiDetailProvider(char).future);
    if (kanji == null) {
      return const KanjiVocabularyGroups(
        onyomi: [],
        kunyomi: [],
        unknown: [],
      );
    }
    return repository.getVocabularyGroups(kanji);
  },
);
final kanjiComponentsProvider =
    FutureProvider.family<List<KanjiComponent>, int>(
  (ref, id) => ref.watch(kanjiRepositoryProvider).getComponents(id),
);
typedef RadicalFormKey = ({int radicalId, String form});

final radicalKanjiIdsProvider = FutureProvider.family<Set<int>, RadicalFormKey>(
  (ref, key) => ref
      .watch(kanjiRepositoryProvider)
      .getKanjiIdsForRadicalForm(key.radicalId, key.form),
);

class RadicalFormsKey {
  RadicalFormsKey({required this.radicalId, required Iterable<String> forms})
      : forms = List.unmodifiable(forms.toSet());

  final int radicalId;
  final List<String> forms;

  @override
  bool operator ==(Object other) =>
      other is RadicalFormsKey &&
      radicalId == other.radicalId &&
      _sameForms(forms, other.forms);

  @override
  int get hashCode => Object.hash(radicalId, Object.hashAll(forms));
}

bool _sameForms(List<String> a, List<String> b) =>
    a.length == b.length && a.indexed.every((entry) => entry.$2 == b[entry.$1]);

final radicalKanjiIdsForFormsProvider =
    FutureProvider.family<Set<int>, RadicalFormsKey>(
  (ref, key) => ref
      .watch(kanjiRepositoryProvider)
      .getKanjiIdsForRadicalForms(key.radicalId, key.forms),
);

final kanjiOccurrencesProvider =
    FutureProvider.family<List<KanjiComponentOccurrence>, int>(
  (ref, id) => ref.watch(kanjiRepositoryProvider).getOccurrences(id),
);

final kanjiDecompositionProvider =
    FutureProvider.autoDispose.family<KanjiDecomposition?, int>(
  (ref, id) => ref.watch(kanjiRepositoryProvider).getKanjiDecomposition(id),
);

final kanjiDecompositionMeaningsProvider =
    FutureProvider.autoDispose.family<Map<String, Kanji>, int>(
  (ref, id) async {
    final tree = await ref.watch(kanjiDecompositionProvider(id).future);
    if (tree == null) return {};
    return ref.watch(kanjiRepositoryProvider).getDecompositionMeanings(tree);
  },
);

final kanjiRefreshProvider =
    AsyncNotifierProvider<KanjiRefreshController, void>(
  KanjiRefreshController.new,
);

class KanjiRefreshController extends AsyncNotifier<void> {
  int _generation = 0;
  @override
  void build() {
    ref.watch(kanjiRepositoryProvider);
    _generation++;
    ref.onDispose(() => _generation++);
  }

  Future<void> refresh() async {
    if (state.isLoading) return;
    final repository = ref.read(kanjiRepositoryProvider);
    final generation = _generation;
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      await repository.recalculate();
      if (generation != _generation) return;
      ref.invalidate(kanjiSnapshotProvider);
      await ref.read(kanjiSnapshotProvider.future);
    });
    if (generation == _generation) state = result;
  }
}
