import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';

part 'home_provider.g.dart';

@riverpod
String greeting(GreetingRef ref) {
  final hour = DateTime.now().hour;
  if (hour < 11) {
    return 'Chào buổi sáng';
  }
  if (hour < 18) {
    return 'Chào buổi chiều';
  }
  return 'Chào buổi tối';
}

@riverpod
Stream<int> totalDueCount(TotalDueCountRef ref) {
  return ref.watch(srsProgressDaoProvider).watchDueWords().map(
        (words) => words.length,
      );
}

@riverpod
Stream<LevelStats> totalLevelStats(TotalLevelStatsRef ref) {
  return ref.watch(srsProgressDaoProvider).watchLevelStats();
}

@riverpod
Stream<List<VocabSearchResult>> homeVocabSuggestions(
  HomeVocabSuggestionsRef ref,
  String query,
) {
  if (query.trim().isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(vocabularyDaoProvider).watchVocabSuggestions(
        query,
        limit: 4,
      );
}
