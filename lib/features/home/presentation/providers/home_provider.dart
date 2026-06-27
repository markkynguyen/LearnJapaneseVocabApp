import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';

part 'home_provider.g.dart';

class FolderSummary {
  const FolderSummary({
    required this.folder,
    required this.totalWords,
    required this.unlearnedCount,
    required this.dueCount,
    required this.lv6Count,
  });

  final Folder folder;
  final int totalWords;
  final int unlearnedCount;
  final int dueCount;
  final int lv6Count;

  double get completionRate {
    if (totalWords == 0) {
      return 0;
    }

    return (totalWords - unlearnedCount) / totalWords;
  }
}

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
Stream<List<FolderSummary>> folderSummaries(FolderSummariesRef ref) {
  return ref.watch(folderDaoProvider).watchFoldersWithCount().map(
        (folders) => folders
            .map(
              (folder) => FolderSummary(
                folder: folder.folder,
                totalWords: folder.totalWords,
                unlearnedCount: folder.unlearnedCount,
                dueCount: folder.dueCount,
                lv6Count: folder.lv6Count,
              ),
            )
            .toList(),
      );
}
