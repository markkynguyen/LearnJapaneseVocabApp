import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/constants/srs_constants.dart';
import 'package:jvocab/core/database/app_database.dart';
import 'package:path/path.dart' as p;

void main() {
  late AppDatabase database;

  group('AppDatabase', skip: _sqliteSkipReason, () {
    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('insertVocab creates default level 0 SRS progress', () async {
      final folderId = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'N5 verbs'),
      );

      final vocabId = await database.vocabularyDao.insertVocab(
        VocabularyCompanion.insert(
          folderId: folderId,
          kana: 'taberu',
          romaji: 'taberu',
          meaning: 'eat',
          note: const Value('synonym: kuu'),
        ),
      );

      final progress =
          await database.srsProgressDao.getProgressByVocabId(vocabId);

      expect(progress, isNotNull);
      expect(progress!.level, SrsConstants.unlearnedLevel);
      expect(progress.intervalDays, 0);
      expect(progress.nextReviewAt, 0);
      expect(progress.lastReviewedAt, isNull);
      expect(await database.srsProgressDao.getDueCount(folderId: folderId), 1);
      final dueWords =
          await database.srsProgressDao.watchDueWords(folderId: folderId).first;
      expect(dueWords.map((item) => item.vocab.id), [vocabId]);
    });

    test('initSettings creates one settings row with quiz and SRS defaults',
        () async {
      final settings = await database.settingsDao.getSettings();

      expect(settings.id, 1);
      expect(settings.sessionSize, 10);
      expect(settings.quizListenCount, 1);
      expect(settings.quizRetryLimit, 2);
      expect(settings.themeMode, 'light');
      expect(settings.flashcardShowKana, isTrue);
      expect(settings.flashcardShowRomaji, isTrue);
      expect(settings.defaultKanaSeeded, isTrue);
      expect(
        settings.srsLevel1IntervalDays,
        SrsConstants.defaultIntervalForLevel(1),
      );
      expect(
        settings.srsLevel6IntervalDays,
        SrsConstants.defaultIntervalForLevel(6),
      );
    });

    test('default kana folders are not recreated after user deletes them',
        () async {
      await database.settingsDao.initSettings();
      final seededFolders = await database.folderDao.watchAllFolders().first;

      expect(seededFolders, isNotEmpty);

      final deletedFolder = seededFolders.first;
      await database.folderDao.deleteFolder(deletedFolder.id);
      await database.settingsDao.initSettings();

      final foldersAfterInit = await database.folderDao.watchAllFolders().first;
      expect(
        foldersAfterInit.map((folder) => folder.id),
        isNot(contains(deletedFolder.id)),
      );
      expect(
        foldersAfterInit.map((folder) => folder.name),
        isNot(contains(deletedFolder.name)),
      );
    });

    test('searchVocab includes note text', () async {
      final folderId = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'N5 adjectives'),
      );

      await database.vocabularyDao.insertVocab(
        VocabularyCompanion.insert(
          folderId: folderId,
          kana: 'ookii',
          romaji: 'ookii',
          meaning: 'big',
          note: const Value('opposite: chiisai'),
        ),
      );

      final results = await database.vocabularyDao.searchVocab(
        folderId,
        'opposite',
      );

      expect(results, hasLength(1));
      expect(results.single.vocab.kana, 'ookii');
    });

    test('fallback session order uses oldest lastReviewedAt first', () async {
      final folderId = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'N5 review'),
      );
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      final vocabA = await _insertVocab(database, folderId, 'a');
      final vocabB = await _insertVocab(database, folderId, 'b');
      final vocabC = await _insertVocab(database, folderId, 'c');
      await _setProgress(
        database,
        vocabA,
        nextReviewAt: now + 1000,
        lastReviewedAt: now - 50,
      );
      await _setProgress(
        database,
        vocabB,
        nextReviewAt: now + 500,
        lastReviewedAt: now - 200,
      );
      await _setProgress(
        database,
        vocabC,
        nextReviewAt: now + 100,
      );

      final result = await database.srsProgressDao.getFallbackVocabForSession(
        folderId: folderId,
        limit: 3,
      );

      expect(result.map((item) => item.vocab.kana), ['c', 'b', 'a']);
    });

    test('fallback session supports favorite-only scope', () async {
      final folderId = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'Favorites'),
      );
      final vocabA = await _insertVocab(database, folderId, 'a');
      final vocabB = await _insertVocab(database, folderId, 'b');
      await database.vocabularyDao.toggleFavorite(vocabB);

      final result = await database.srsProgressDao.getFallbackVocabForSession(
        folderId: folderId,
        limit: 10,
        excludeIds: [vocabA],
        favoritesOnly: true,
      );

      expect(result, hasLength(1));
      expect(result.single.vocab.id, vocabB);
    });

    test('level stats count learned levels and exclude level 0 from learned',
        () async {
      final folderA = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'Folder A'),
      );
      final folderB = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'Folder B'),
      );

      final lv0 = await _insertVocab(database, folderA, 'lv0');
      final lv1 = await _insertVocab(database, folderA, 'lv1');
      final lv6 = await _insertVocab(database, folderA, 'lv6');
      final other = await _insertVocab(database, folderB, 'other');

      await _setProgress(database, lv0, level: 0);
      await _setProgress(database, lv1, level: 1);
      await _setProgress(database, lv6, level: 6);
      await _setProgress(database, other, level: 2);

      final folderStats = await database.srsProgressDao
          .watchLevelStats(folderId: folderA)
          .first;
      final totalStats = await database.srsProgressDao.watchLevelStats().first;

      expect(folderStats.totalWords, 3);
      expect(folderStats.learnedWords, 2);
      expect(folderStats.countForLevel(1), 1);
      expect(folderStats.countForLevel(6), 1);
      expect(totalStats.totalWords, 4);
      expect(totalStats.learnedWords, 3);
      expect(totalStats.countForLevel(2), 1);
    });
  });
}

Future<int> _insertVocab(AppDatabase database, int folderId, String kana) {
  return database.vocabularyDao.insertVocab(
    VocabularyCompanion.insert(
      folderId: folderId,
      kana: kana,
      romaji: kana,
      meaning: kana,
    ),
  );
}

Future<void> _setProgress(
  AppDatabase database,
  int vocabId, {
  int? nextReviewAt,
  int level = 1,
  int? lastReviewedAt,
}) {
  return database.srsProgressDao.updateProgressByVocabId(
    vocabId,
    SrsProgressCompanion(
      level: Value(level),
      intervalDays: const Value(1),
      nextReviewAt:
          Value(nextReviewAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000),
      lastReviewedAt: Value(lastReviewedAt),
    ),
  );
}

String? get _sqliteSkipReason {
  if (!Platform.isWindows) {
    return null;
  }

  final path = Platform.environment['PATH'] ?? '';
  final hasSqliteDll = path
      .split(';')
      .where((entry) => entry.trim().isNotEmpty)
      .any((entry) => File(p.join(entry, 'sqlite3.dll')).existsSync());

  if (hasSqliteDll || File('sqlite3.dll').existsSync()) {
    return null;
  }

  return 'sqlite3.dll is not available to the Dart VM on Windows. '
      'Flutter apps get SQLite from sqlite3_flutter_libs at runtime.';
}
