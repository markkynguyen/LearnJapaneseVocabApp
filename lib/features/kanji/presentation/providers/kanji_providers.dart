import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cloud/cloud_store.dart';
import '../../../../core/connectivity/cloud_connectivity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/kanji_repository.dart';
import '../../domain/kanji_models.dart';

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
final kanjiComponentsProvider =
    FutureProvider.family<List<KanjiComponent>, int>(
  (ref, id) => ref.watch(kanjiRepositoryProvider).getComponents(id),
);
final radicalKanjiIdsProvider = FutureProvider.family<Set<int>, int>(
  (ref, id) => ref.watch(kanjiRepositoryProvider).getKanjiIdsForRadical(id),
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
