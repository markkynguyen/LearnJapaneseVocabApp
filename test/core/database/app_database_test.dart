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
      expect(await database.srsProgressDao.getDueCount(folderId: folderId), 0);
      final dueWords =
          await database.srsProgressDao.watchDueWords(folderId: folderId).first;
      expect(dueWords, isEmpty);
    });

    test('initSettings creates one settings row with quiz and SRS defaults',
        () async {
      final settings = await database.settingsDao.getSettings();

      expect(settings.id, 1);
      expect(settings.sessionSize, 10);
      expect(settings.quizListenCount, 1);
      expect(settings.quizRetryLimit, 2);
      expect(settings.newWordSessionSize, 5);
      expect(settings.newWordListenCount, 1);
      expect(settings.newWordWriteCount, 1);
      expect(settings.newWordChooseWordCount, 1);
      expect(settings.newWordChooseMeaningCount, 1);
      expect(settings.quizJapaneseScript, 'kanji');
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
      await _setProgress(database, vocabB, level: 1);

      final result = await database.srsProgressDao.getFallbackVocabForSession(
        folderId: folderId,
        limit: 10,
        excludeIds: [vocabA],
        favoritesOnly: true,
      );

      expect(result, hasLength(1));
      expect(result.single.vocab.id, vocabB);
    });

    test('review excludes level 0 and learning orders attempted words first',
        () async {
      final folderId = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'Learning order'),
      );
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final attemptedRecent = await _insertVocab(database, folderId, 'recent');
      final attemptedOld = await _insertVocab(database, folderId, 'old');
      final untouched = await _insertVocab(database, folderId, 'untouched');
      final learned = await _insertVocab(database, folderId, 'learned');

      await _setProgress(
        database,
        attemptedRecent,
        level: 0,
        lastReviewedAt: now - 50,
      );
      await _setProgress(
        database,
        attemptedOld,
        level: 0,
        lastReviewedAt: now - 200,
      );
      await _setProgress(database, learned, level: 1, nextReviewAt: 0);

      final newWords = await database.srsProgressDao.getNewVocabForLearning(
        folderId: folderId,
        limit: 10,
      );
      final dueWords = await database.srsProgressDao
          .getDueVocabForSession(folderId: folderId, limit: 10);

      expect(
        newWords.map((item) => item.vocab.id),
        [attemptedOld, attemptedRecent, untouched],
      );
      expect(dueWords.map((item) => item.vocab.id), [learned]);
      expect(
        await database.srsProgressDao.getUnlearnedCount(folderId: folderId),
        3,
      );
    });

    test('global suggestions search four fields and rank exact matches first',
        () async {
      final folderA = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'Động từ N5'),
      );
      final folderB = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'Từ bổ sung'),
      );

      final containsId = await _insertSearchVocab(
        database,
        folderA,
        kanji: 'お食べる',
        kana: 'おたべる',
        romaji: 'otaberu',
        meaning: 'to eat politely',
        createdAt: 300,
      );
      final prefixId = await _insertSearchVocab(
        database,
        folderB,
        kanji: '食べ物',
        kana: 'たべもの',
        romaji: 'taberumono',
        meaning: 'food',
        createdAt: 200,
      );
      final exactId = await _insertSearchVocab(
        database,
        folderA,
        kanji: '食べる',
        kana: 'たべる',
        romaji: 'taberu',
        meaning: 'eat',
        note: 'secret-note-only',
        createdAt: 100,
      );

      final romajiResults =
          await database.vocabularyDao.watchVocabSuggestions('TABERU').first;
      final kanjiResults =
          await database.vocabularyDao.watchVocabSuggestions('食べる').first;
      final kanaResults =
          await database.vocabularyDao.watchVocabSuggestions('たべ').first;
      final meaningResults =
          await database.vocabularyDao.watchVocabSuggestions('EAT').first;
      final noteResults = await database.vocabularyDao
          .watchVocabSuggestions('secret-note-only')
          .first;

      expect(
        romajiResults.map((result) => result.item.vocab.id),
        [exactId, prefixId, containsId],
      );
      expect(romajiResults.first.folder.name, 'Động từ N5');
      expect(kanjiResults.first.item.vocab.id, exactId);
      expect(
        kanaResults.map((result) => result.item.vocab.id),
        containsAll([exactId, prefixId, containsId]),
      );
      expect(
        meaningResults.map((result) => result.item.vocab.id),
        containsAll([exactId, containsId]),
      );
      expect(noteResults, isEmpty);
    });

    test('global suggestions enforce the requested result limit', () async {
      final folderId = await database.folderDao.insertFolder(
        FoldersCompanion.insert(name: 'Limit'),
      );
      for (var index = 0; index < 6; index++) {
        await _insertSearchVocab(
          database,
          folderId,
          kana: 'かな$index',
          romaji: 'common$index',
          meaning: 'shared result $index',
          createdAt: index,
        );
      }

      final results = await database.vocabularyDao
          .watchVocabSuggestions('common', limit: 4)
          .first;

      expect(results, hasLength(4));
      expect(
        results.map((result) => result.item.vocab.createdAt),
        [5, 4, 3, 2],
      );
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

Future<int> _insertSearchVocab(
  AppDatabase database,
  int folderId, {
  String? kanji,
  required String kana,
  required String romaji,
  required String meaning,
  String? note,
  required int createdAt,
}) {
  return database.vocabularyDao.insertVocab(
    VocabularyCompanion.insert(
      folderId: folderId,
      kanji: Value(kanji),
      kana: kana,
      romaji: romaji,
      meaning: meaning,
      note: Value(note),
      createdAt: Value(createdAt),
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
