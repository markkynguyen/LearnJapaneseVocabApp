import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cloud/cloud_store.dart';
import '../../../../core/models/app_models.dart';

part 'home_provider.g.dart';

@riverpod
String greeting(GreetingRef ref) {
  final hour = DateTime.now().hour;
  if (hour < 11) return 'Chào buổi sáng';
  if (hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

@riverpod
Future<int> totalDueCount(TotalDueCountRef ref) =>
    ref.watch(cloudStoreProvider).getDueCount();

@riverpod
Future<LevelStats> totalLevelStats(TotalLevelStatsRef ref) =>
    ref.watch(cloudStoreProvider).getLevelStats();

@riverpod
Future<List<VocabSearchResult>> homeVocabSuggestions(
  HomeVocabSuggestionsRef ref,
  String query,
) =>
    ref.watch(cloudStoreProvider).searchAllVocab(query, limit: 4);
