import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/srs_constants.dart';
import 'database_connection_native.dart'
    if (dart.library.html) 'database_connection_web.dart';

part 'app_database.g.dart';

int _nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

enum VocabSortMode {
  newest,
  oldest,
  dueTime;

  static VocabSortMode fromValue(String value) {
    return VocabSortMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => VocabSortMode.newest,
    );
  }
}

class FolderWithCount {
  const FolderWithCount({
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
}

class VocabWithProgress {
  const VocabWithProgress({
    required this.vocab,
    required this.progress,
  });

  final VocabularyEntry vocab;
  final SrsProgressEntry progress;
}

class LevelStats {
  const LevelStats({
    required this.totalWords,
    required this.levelCounts,
  });

  final int totalWords;
  final Map<int, int> levelCounts;

  int countForLevel(int level) => levelCounts[level] ?? 0;

  int get learnedWords {
    var total = 0;
    for (var level = SrsConstants.minLevel;
        level <= SrsConstants.maxLevel;
        level++) {
      total += countForLevel(level);
    }
    return total;
  }
}

@DataClassName('Folder')
class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get description => text().nullable()();
  TextColumn get color => text().withDefault(const Constant('#6366F1'))();
  IntColumn get createdAt => integer().clientDefault(_nowSeconds)();
}

@DataClassName('VocabularyEntry')
class Vocabulary extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get folderId => integer().references(
        Folders,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get kanji => text().nullable()();
  TextColumn get kana => text().withLength(min: 1)();
  TextColumn get romaji => text().withLength(min: 1)();
  TextColumn get meaning => text().withLength(min: 1)();
  TextColumn get pitchAccent => text().nullable()();
  TextColumn get example => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get audioPath => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer().clientDefault(_nowSeconds)();
}

@DataClassName('SrsProgressEntry')
class SrsProgress extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vocabId => integer().references(
        Vocabulary,
        #id,
        onDelete: KeyAction.cascade,
      )();
  IntColumn get level => integer().withDefault(const Constant(0))();
  RealColumn get intervalDays => real().withDefault(const Constant(0))();
  IntColumn get nextReviewAt => integer()();
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();
  IntColumn get lastReviewedAt => integer().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {vocabId},
      ];
}

@DataClassName('AppSettings')
class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get notifyEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get notifyHour => integer().withDefault(const Constant(8))();
  IntColumn get notifyMinute => integer().withDefault(const Constant(0))();
  IntColumn get sessionSize => integer().withDefault(const Constant(10))();
  TextColumn get quizDirection =>
      text().withDefault(const Constant('ja_to_vi'))();
  IntColumn get quizListenCount => integer().withDefault(const Constant(1))();
  IntColumn get quizReadCount => integer().withDefault(const Constant(1))();
  IntColumn get quizWriteCount => integer().withDefault(const Constant(1))();
  IntColumn get quizChooseWordCount =>
      integer().withDefault(const Constant(1))();
  IntColumn get quizChooseMeaningCount =>
      integer().withDefault(const Constant(1))();
  IntColumn get quizRetryLimit => integer().withDefault(const Constant(2))();
  IntColumn get newWordSessionSize =>
      integer().withDefault(const Constant(5))();
  IntColumn get newWordListenCount =>
      integer().withDefault(const Constant(1))();
  IntColumn get newWordWriteCount => integer().withDefault(const Constant(1))();
  IntColumn get newWordChooseWordCount =>
      integer().withDefault(const Constant(1))();
  IntColumn get newWordChooseMeaningCount =>
      integer().withDefault(const Constant(1))();
  TextColumn get quizJapaneseScript =>
      text().withDefault(const Constant('kanji'))();
  TextColumn get themeMode => text().withDefault(const Constant('light'))();
  RealColumn get srsLevel1IntervalDays =>
      real().withDefault(const Constant(2 / 24))();
  RealColumn get srsLevel2IntervalDays =>
      real().withDefault(const Constant(1.0))();
  RealColumn get srsLevel3IntervalDays =>
      real().withDefault(const Constant(2.0))();
  RealColumn get srsLevel4IntervalDays =>
      real().withDefault(const Constant(3.0))();
  RealColumn get srsLevel5IntervalDays =>
      real().withDefault(const Constant(5.0))();
  RealColumn get srsLevel6IntervalDays =>
      real().withDefault(const Constant(8.0))();
  BoolColumn get flashcardShowKana =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get flashcardShowRomaji =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get defaultKanaSeeded =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    Folders,
    Vocabulary,
    SrsProgress,
    Settings,
  ],
  daos: [
    FolderDao,
    VocabularyDao,
    SrsProgressDao,
    SettingsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(settings, settings.themeMode);
          }
          if (from < 3) {
            // Version 3 changes new-word defaults to Lv 0 in generated code.
            // Existing SRS rows keep their current learned levels.
          }
          if (from < 4) {
            await m.addColumn(settings, settings.flashcardShowKana);
            await m.addColumn(settings, settings.flashcardShowRomaji);
          }
          if (from < 5) {
            await m.addColumn(settings, settings.defaultKanaSeeded);
            await customUpdate(
              'UPDATE settings SET default_kana_seeded = 1 WHERE id = 1',
            );
          }
          if (from < 6) {
            await m.addColumn(settings, settings.newWordSessionSize);
            await m.addColumn(settings, settings.newWordListenCount);
            await m.addColumn(settings, settings.newWordWriteCount);
            await m.addColumn(settings, settings.newWordChooseWordCount);
            await m.addColumn(settings, settings.newWordChooseMeaningCount);
            await m.addColumn(settings, settings.quizJapaneseScript);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  Future<void> seedDefaultKanaFolders() async {
    await transaction(() async {
      await _seedKanaFolder(
        name: 'Bảng chữ cái Hiragana',
        description: 'Bộ chữ hiragana cơ bản để bắt đầu học tiếng Nhật.',
        color: '#22C55E',
        entries: _hiraganaEntries,
      );
      await _seedKanaFolder(
        name: 'Bảng chữ cái Katakana',
        description: 'Bộ chữ katakana cơ bản dùng cho từ mượn và tên riêng.',
        color: '#0EA5E9',
        entries: _katakanaEntries,
      );
      await _seedKanaFolder(
        name: 'Biến âm',
        description:
            'Các âm có dấu dakuten và handakuten trong hiragana, katakana.',
        color: '#F97316',
        entries: _voicedKanaEntries,
      );
      await _seedKanaFolder(
        name: 'Âm ghép',
        description: 'Các âm ghép với ゃ, ゅ, ょ trong hiragana và katakana.',
        color: '#A855F7',
        entries: _compoundKanaEntries,
      );
    });
  }

  Future<void> _seedKanaFolder({
    required String name,
    required String description,
    required String color,
    required List<_DefaultKanaEntry> entries,
  }) async {
    final existingFolder = await (select(folders)
          ..where((tbl) => tbl.name.equals(name)))
        .getSingleOrNull();
    final folderId = existingFolder?.id ??
        await into(folders).insert(
          FoldersCompanion.insert(
            name: name,
            description: Value(description),
            color: Value(color),
          ),
        );

    final existingKana = await (select(vocabulary)
          ..where((tbl) => tbl.folderId.equals(folderId)))
        .map((row) => row.kana)
        .get();
    final existingKanaSet = existingKana.toSet();

    for (final entry in entries) {
      if (existingKanaSet.contains(entry.kana)) {
        continue;
      }
      final vocabId = await into(vocabulary).insert(
        VocabularyCompanion.insert(
          folderId: folderId,
          kana: entry.kana,
          romaji: entry.romaji,
          meaning: entry.meaning,
          pitchAccent: const Value('L'),
          note: Value(entry.note),
        ),
      );
      await into(srsProgress).insert(
        SrsProgressCompanion.insert(
          vocabId: vocabId,
          level: const Value(SrsConstants.unlearnedLevel),
          intervalDays: const Value(0),
          nextReviewAt: 0,
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }
}

class _DefaultKanaEntry {
  const _DefaultKanaEntry(this.kana, this.romaji, this.meaning, this.note);

  final String kana;
  final String romaji;
  final String meaning;
  final String note;
}

const _hiraganaEntries = [
  _DefaultKanaEntry('あ', 'a', 'a', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('い', 'i', 'i', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('う', 'u', 'u', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('え', 'e', 'e', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('お', 'o', 'o', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('か', 'ka', 'ka', 'Hàng k.'),
  _DefaultKanaEntry('き', 'ki', 'ki', 'Hàng k.'),
  _DefaultKanaEntry('く', 'ku', 'ku', 'Hàng k.'),
  _DefaultKanaEntry('け', 'ke', 'ke', 'Hàng k.'),
  _DefaultKanaEntry('こ', 'ko', 'ko', 'Hàng k.'),
  _DefaultKanaEntry('さ', 'sa', 'sa', 'Hàng s.'),
  _DefaultKanaEntry('し', 'shi', 'shi', 'Hàng s.'),
  _DefaultKanaEntry('す', 'su', 'su', 'Hàng s.'),
  _DefaultKanaEntry('せ', 'se', 'se', 'Hàng s.'),
  _DefaultKanaEntry('そ', 'so', 'so', 'Hàng s.'),
  _DefaultKanaEntry('た', 'ta', 'ta', 'Hàng t.'),
  _DefaultKanaEntry('ち', 'chi', 'chi', 'Hàng t.'),
  _DefaultKanaEntry('つ', 'tsu', 'tsu', 'Hàng t.'),
  _DefaultKanaEntry('て', 'te', 'te', 'Hàng t.'),
  _DefaultKanaEntry('と', 'to', 'to', 'Hàng t.'),
  _DefaultKanaEntry('な', 'na', 'na', 'Hàng n.'),
  _DefaultKanaEntry('に', 'ni', 'ni', 'Hàng n.'),
  _DefaultKanaEntry('ぬ', 'nu', 'nu', 'Hàng n.'),
  _DefaultKanaEntry('ね', 'ne', 'ne', 'Hàng n.'),
  _DefaultKanaEntry('の', 'no', 'no', 'Hàng n.'),
  _DefaultKanaEntry('は', 'ha', 'ha', 'Hàng h.'),
  _DefaultKanaEntry('ひ', 'hi', 'hi', 'Hàng h.'),
  _DefaultKanaEntry('ふ', 'fu', 'fu', 'Hàng h.'),
  _DefaultKanaEntry('へ', 'he', 'he', 'Hàng h.'),
  _DefaultKanaEntry('ほ', 'ho', 'ho', 'Hàng h.'),
  _DefaultKanaEntry('ま', 'ma', 'ma', 'Hàng m.'),
  _DefaultKanaEntry('み', 'mi', 'mi', 'Hàng m.'),
  _DefaultKanaEntry('む', 'mu', 'mu', 'Hàng m.'),
  _DefaultKanaEntry('め', 'me', 'me', 'Hàng m.'),
  _DefaultKanaEntry('も', 'mo', 'mo', 'Hàng m.'),
  _DefaultKanaEntry('や', 'ya', 'ya', 'Hàng y.'),
  _DefaultKanaEntry('ゆ', 'yu', 'yu', 'Hàng y.'),
  _DefaultKanaEntry('よ', 'yo', 'yo', 'Hàng y.'),
  _DefaultKanaEntry('ら', 'ra', 'ra', 'Hàng r.'),
  _DefaultKanaEntry('り', 'ri', 'ri', 'Hàng r.'),
  _DefaultKanaEntry('る', 'ru', 'ru', 'Hàng r.'),
  _DefaultKanaEntry('れ', 're', 're', 'Hàng r.'),
  _DefaultKanaEntry('ろ', 'ro', 'ro', 'Hàng r.'),
  _DefaultKanaEntry('わ', 'wa', 'wa', 'Hàng w.'),
  _DefaultKanaEntry('を', 'wo', 'wo', 'Dùng làm trợ từ を.'),
  _DefaultKanaEntry('ん', 'n', 'n', 'Mũi ん.'),
];

const _katakanaEntries = [
  _DefaultKanaEntry('ア', 'a', 'a', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('イ', 'i', 'i', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('ウ', 'u', 'u', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('エ', 'e', 'e', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('オ', 'o', 'o', 'Hàng nguyên âm.'),
  _DefaultKanaEntry('カ', 'ka', 'ka', 'Hàng k.'),
  _DefaultKanaEntry('キ', 'ki', 'ki', 'Hàng k.'),
  _DefaultKanaEntry('ク', 'ku', 'ku', 'Hàng k.'),
  _DefaultKanaEntry('ケ', 'ke', 'ke', 'Hàng k.'),
  _DefaultKanaEntry('コ', 'ko', 'ko', 'Hàng k.'),
  _DefaultKanaEntry('サ', 'sa', 'sa', 'Hàng s.'),
  _DefaultKanaEntry('シ', 'shi', 'shi', 'Hàng s.'),
  _DefaultKanaEntry('ス', 'su', 'su', 'Hàng s.'),
  _DefaultKanaEntry('セ', 'se', 'se', 'Hàng s.'),
  _DefaultKanaEntry('ソ', 'so', 'so', 'Hàng s.'),
  _DefaultKanaEntry('タ', 'ta', 'ta', 'Hàng t.'),
  _DefaultKanaEntry('チ', 'chi', 'chi', 'Hàng t.'),
  _DefaultKanaEntry('ツ', 'tsu', 'tsu', 'Hàng t.'),
  _DefaultKanaEntry('テ', 'te', 'te', 'Hàng t.'),
  _DefaultKanaEntry('ト', 'to', 'to', 'Hàng t.'),
  _DefaultKanaEntry('ナ', 'na', 'na', 'Hàng n.'),
  _DefaultKanaEntry('ニ', 'ni', 'ni', 'Hàng n.'),
  _DefaultKanaEntry('ヌ', 'nu', 'nu', 'Hàng n.'),
  _DefaultKanaEntry('ネ', 'ne', 'ne', 'Hàng n.'),
  _DefaultKanaEntry('ノ', 'no', 'no', 'Hàng n.'),
  _DefaultKanaEntry('ハ', 'ha', 'ha', 'Hàng h.'),
  _DefaultKanaEntry('ヒ', 'hi', 'hi', 'Hàng h.'),
  _DefaultKanaEntry('フ', 'fu', 'fu', 'Hàng h.'),
  _DefaultKanaEntry('ヘ', 'he', 'he', 'Hàng h.'),
  _DefaultKanaEntry('ホ', 'ho', 'ho', 'Hàng h.'),
  _DefaultKanaEntry('マ', 'ma', 'ma', 'Hàng m.'),
  _DefaultKanaEntry('ミ', 'mi', 'mi', 'Hàng m.'),
  _DefaultKanaEntry('ム', 'mu', 'mu', 'Hàng m.'),
  _DefaultKanaEntry('メ', 'me', 'me', 'Hàng m.'),
  _DefaultKanaEntry('モ', 'mo', 'mo', 'Hàng m.'),
  _DefaultKanaEntry('ヤ', 'ya', 'ya', 'Hàng y.'),
  _DefaultKanaEntry('ユ', 'yu', 'yu', 'Hàng y.'),
  _DefaultKanaEntry('ヨ', 'yo', 'yo', 'Hàng y.'),
  _DefaultKanaEntry('ラ', 'ra', 'ra', 'Hàng r.'),
  _DefaultKanaEntry('リ', 'ri', 'ri', 'Hàng r.'),
  _DefaultKanaEntry('ル', 'ru', 'ru', 'Hàng r.'),
  _DefaultKanaEntry('レ', 're', 're', 'Hàng r.'),
  _DefaultKanaEntry('ロ', 'ro', 'ro', 'Hàng r.'),
  _DefaultKanaEntry('ワ', 'wa', 'wa', 'Hàng w.'),
  _DefaultKanaEntry('ヲ', 'wo', 'wo', 'Katakana ヲ ít dùng trong hiện đại.'),
  _DefaultKanaEntry('ン', 'n', 'n', 'Mũi ン.'),
];

const _voicedKanaEntries = [
  _DefaultKanaEntry('が', 'ga', 'ga', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('ぎ', 'gi', 'gi', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('ぐ', 'gu', 'gu', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('げ', 'ge', 'ge', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('ご', 'go', 'go', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('ざ', 'za', 'za', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('じ', 'ji', 'ji', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('ず', 'zu', 'zu', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('ぜ', 'ze', 'ze', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('ぞ', 'zo', 'zo', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('だ', 'da', 'da', 'Biến âm hàng t với dakuten.'),
  _DefaultKanaEntry('ぢ', 'ji', 'ji', 'Biến âm hàng t với dakuten, ít dùng.'),
  _DefaultKanaEntry('づ', 'zu', 'zu', 'Biến âm hàng t với dakuten, ít dùng.'),
  _DefaultKanaEntry('で', 'de', 'de', 'Biến âm hàng t với dakuten.'),
  _DefaultKanaEntry('ど', 'do', 'do', 'Biến âm hàng t với dakuten.'),
  _DefaultKanaEntry('ば', 'ba', 'ba', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('び', 'bi', 'bi', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('ぶ', 'bu', 'bu', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('べ', 'be', 'be', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('ぼ', 'bo', 'bo', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('ぱ', 'pa', 'pa', 'Biến âm hàng h với handakuten.'),
  _DefaultKanaEntry('ぴ', 'pi', 'pi', 'Biến âm hàng h với handakuten.'),
  _DefaultKanaEntry('ぷ', 'pu', 'pu', 'Biến âm hàng h với handakuten.'),
  _DefaultKanaEntry('ぺ', 'pe', 'pe', 'Biến âm hàng h với handakuten.'),
  _DefaultKanaEntry('ぽ', 'po', 'po', 'Biến âm hàng h với handakuten.'),
  _DefaultKanaEntry('ガ', 'ga', 'ga', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('ギ', 'gi', 'gi', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('グ', 'gu', 'gu', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('ゲ', 'ge', 'ge', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('ゴ', 'go', 'go', 'Biến âm hàng k với dakuten.'),
  _DefaultKanaEntry('ザ', 'za', 'za', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('ジ', 'ji', 'ji', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('ズ', 'zu', 'zu', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('ゼ', 'ze', 'ze', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('ゾ', 'zo', 'zo', 'Biến âm hàng s với dakuten.'),
  _DefaultKanaEntry('ダ', 'da', 'da', 'Biến âm hàng t với dakuten.'),
  _DefaultKanaEntry('ヂ', 'ji', 'ji', 'Biến âm hàng t với dakuten, ít dùng.'),
  _DefaultKanaEntry('ヅ', 'zu', 'zu', 'Biến âm hàng t với dakuten, ít dùng.'),
  _DefaultKanaEntry('デ', 'de', 'de', 'Biến âm hàng t với dakuten.'),
  _DefaultKanaEntry('ド', 'do', 'do', 'Biến âm hàng t với dakuten.'),
  _DefaultKanaEntry('バ', 'ba', 'ba', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('ビ', 'bi', 'bi', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('ブ', 'bu', 'bu', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('ベ', 'be', 'be', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('ボ', 'bo', 'bo', 'Biến âm hàng h với dakuten.'),
  _DefaultKanaEntry('パ', 'pa', 'pa', 'Biến âm hàng h với handakuten.'),
  _DefaultKanaEntry('ピ', 'pi', 'pi', 'Biến âm hàng h với handakuten.'),
  _DefaultKanaEntry('プ', 'pu', 'pu', 'Biến âm hàng h với handakuten.'),
  _DefaultKanaEntry('ペ', 'pe', 'pe', 'Biến âm hàng h với handakuten.'),
  _DefaultKanaEntry('ポ', 'po', 'po', 'Biến âm hàng h với handakuten.'),
];

const _compoundKanaEntries = [
  _DefaultKanaEntry('きゃ', 'kya', 'kya', 'Âm ghép hàng k.'),
  _DefaultKanaEntry('きゅ', 'kyu', 'kyu', 'Âm ghép hàng k.'),
  _DefaultKanaEntry('きょ', 'kyo', 'kyo', 'Âm ghép hàng k.'),
  _DefaultKanaEntry('しゃ', 'sha', 'sha', 'Âm ghép hàng s.'),
  _DefaultKanaEntry('しゅ', 'shu', 'shu', 'Âm ghép hàng s.'),
  _DefaultKanaEntry('しょ', 'sho', 'sho', 'Âm ghép hàng s.'),
  _DefaultKanaEntry('ちゃ', 'cha', 'cha', 'Âm ghép hàng t.'),
  _DefaultKanaEntry('ちゅ', 'chu', 'chu', 'Âm ghép hàng t.'),
  _DefaultKanaEntry('ちょ', 'cho', 'cho', 'Âm ghép hàng t.'),
  _DefaultKanaEntry('にゃ', 'nya', 'nya', 'Âm ghép hàng n.'),
  _DefaultKanaEntry('にゅ', 'nyu', 'nyu', 'Âm ghép hàng n.'),
  _DefaultKanaEntry('にょ', 'nyo', 'nyo', 'Âm ghép hàng n.'),
  _DefaultKanaEntry('ひゃ', 'hya', 'hya', 'Âm ghép hàng h.'),
  _DefaultKanaEntry('ひゅ', 'hyu', 'hyu', 'Âm ghép hàng h.'),
  _DefaultKanaEntry('ひょ', 'hyo', 'hyo', 'Âm ghép hàng h.'),
  _DefaultKanaEntry('みゃ', 'mya', 'mya', 'Âm ghép hàng m.'),
  _DefaultKanaEntry('みゅ', 'myu', 'myu', 'Âm ghép hàng m.'),
  _DefaultKanaEntry('みょ', 'myo', 'myo', 'Âm ghép hàng m.'),
  _DefaultKanaEntry('りゃ', 'rya', 'rya', 'Âm ghép hàng r.'),
  _DefaultKanaEntry('りゅ', 'ryu', 'ryu', 'Âm ghép hàng r.'),
  _DefaultKanaEntry('りょ', 'ryo', 'ryo', 'Âm ghép hàng r.'),
  _DefaultKanaEntry('ぎゃ', 'gya', 'gya', 'Âm ghép biến âm hàng g.'),
  _DefaultKanaEntry('ぎゅ', 'gyu', 'gyu', 'Âm ghép biến âm hàng g.'),
  _DefaultKanaEntry('ぎょ', 'gyo', 'gyo', 'Âm ghép biến âm hàng g.'),
  _DefaultKanaEntry('じゃ', 'ja', 'ja', 'Âm ghép biến âm hàng j.'),
  _DefaultKanaEntry('じゅ', 'ju', 'ju', 'Âm ghép biến âm hàng j.'),
  _DefaultKanaEntry('じょ', 'jo', 'jo', 'Âm ghép biến âm hàng j.'),
  _DefaultKanaEntry('びゃ', 'bya', 'bya', 'Âm ghép biến âm hàng b.'),
  _DefaultKanaEntry('びゅ', 'byu', 'byu', 'Âm ghép biến âm hàng b.'),
  _DefaultKanaEntry('びょ', 'byo', 'byo', 'Âm ghép biến âm hàng b.'),
  _DefaultKanaEntry('ぴゃ', 'pya', 'pya', 'Âm ghép biến âm hàng p.'),
  _DefaultKanaEntry('ぴゅ', 'pyu', 'pyu', 'Âm ghép biến âm hàng p.'),
  _DefaultKanaEntry('ぴょ', 'pyo', 'pyo', 'Âm ghép biến âm hàng p.'),
  _DefaultKanaEntry('キャ', 'kya', 'kya', 'Âm ghép hàng k.'),
  _DefaultKanaEntry('キュ', 'kyu', 'kyu', 'Âm ghép hàng k.'),
  _DefaultKanaEntry('キョ', 'kyo', 'kyo', 'Âm ghép hàng k.'),
  _DefaultKanaEntry('シャ', 'sha', 'sha', 'Âm ghép hàng s.'),
  _DefaultKanaEntry('シュ', 'shu', 'shu', 'Âm ghép hàng s.'),
  _DefaultKanaEntry('ショ', 'sho', 'sho', 'Âm ghép hàng s.'),
  _DefaultKanaEntry('チャ', 'cha', 'cha', 'Âm ghép hàng t.'),
  _DefaultKanaEntry('チュ', 'chu', 'chu', 'Âm ghép hàng t.'),
  _DefaultKanaEntry('チョ', 'cho', 'cho', 'Âm ghép hàng t.'),
  _DefaultKanaEntry('ニャ', 'nya', 'nya', 'Âm ghép hàng n.'),
  _DefaultKanaEntry('ニュ', 'nyu', 'nyu', 'Âm ghép hàng n.'),
  _DefaultKanaEntry('ニョ', 'nyo', 'nyo', 'Âm ghép hàng n.'),
  _DefaultKanaEntry('ヒャ', 'hya', 'hya', 'Âm ghép hàng h.'),
  _DefaultKanaEntry('ヒュ', 'hyu', 'hyu', 'Âm ghép hàng h.'),
  _DefaultKanaEntry('ヒョ', 'hyo', 'hyo', 'Âm ghép hàng h.'),
  _DefaultKanaEntry('ミャ', 'mya', 'mya', 'Âm ghép hàng m.'),
  _DefaultKanaEntry('ミュ', 'myu', 'myu', 'Âm ghép hàng m.'),
  _DefaultKanaEntry('ミョ', 'myo', 'myo', 'Âm ghép hàng m.'),
  _DefaultKanaEntry('リャ', 'rya', 'rya', 'Âm ghép hàng r.'),
  _DefaultKanaEntry('リュ', 'ryu', 'ryu', 'Âm ghép hàng r.'),
  _DefaultKanaEntry('リョ', 'ryo', 'ryo', 'Âm ghép hàng r.'),
  _DefaultKanaEntry('ギャ', 'gya', 'gya', 'Âm ghép biến âm hàng g.'),
  _DefaultKanaEntry('ギュ', 'gyu', 'gyu', 'Âm ghép biến âm hàng g.'),
  _DefaultKanaEntry('ギョ', 'gyo', 'gyo', 'Âm ghép biến âm hàng g.'),
  _DefaultKanaEntry('ジャ', 'ja', 'ja', 'Âm ghép biến âm hàng j.'),
  _DefaultKanaEntry('ジュ', 'ju', 'ju', 'Âm ghép biến âm hàng j.'),
  _DefaultKanaEntry('ジョ', 'jo', 'jo', 'Âm ghép biến âm hàng j.'),
  _DefaultKanaEntry('ビャ', 'bya', 'bya', 'Âm ghép biến âm hàng b.'),
  _DefaultKanaEntry('ビュ', 'byu', 'byu', 'Âm ghép biến âm hàng b.'),
  _DefaultKanaEntry('ビョ', 'byo', 'byo', 'Âm ghép biến âm hàng b.'),
  _DefaultKanaEntry('ピャ', 'pya', 'pya', 'Âm ghép biến âm hàng p.'),
  _DefaultKanaEntry('ピュ', 'pyu', 'pyu', 'Âm ghép biến âm hàng p.'),
  _DefaultKanaEntry('ピョ', 'pyo', 'pyo', 'Âm ghép biến âm hàng p.'),
];

@DriftAccessor(tables: [Folders, Vocabulary, SrsProgress])
class FolderDao extends DatabaseAccessor<AppDatabase> with _$FolderDaoMixin {
  FolderDao(super.db);

  Future<int> insertFolder(FoldersCompanion folder) {
    return into(folders).insert(folder);
  }

  Future<bool> updateFolder(FoldersCompanion folder) {
    return update(folders).replace(folder);
  }

  Future<int> deleteFolder(int id) {
    return (delete(folders)..where((tbl) => tbl.id.equals(id))).go();
  }

  Stream<List<Folder>> watchAllFolders() {
    return (select(folders)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
        .watch();
  }

  Future<Folder?> getFolderById(int id) {
    return (select(folders)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<FolderWithCount>> watchFoldersWithCount() {
    final now = _nowSeconds();
    return customSelect(
      '''
      SELECT
        f.id,
        f.name,
        f.description,
        f.color,
        f.created_at,
        COUNT(v.id) AS total_words,
        COALESCE(SUM(CASE WHEN sp.level = 0 THEN 1 ELSE 0 END), 0) AS unlearned_count,
        COALESCE(SUM(CASE WHEN sp.level > 0 AND sp.next_review_at <= ? THEN 1 ELSE 0 END), 0) AS due_count,
        COALESCE(SUM(CASE WHEN sp.level = 6 THEN 1 ELSE 0 END), 0) AS lv6_count
      FROM folders f
      LEFT JOIN vocabulary v ON v.folder_id = f.id
      LEFT JOIN srs_progress sp ON sp.vocab_id = v.id
      GROUP BY f.id
      ORDER BY f.created_at DESC
      ''',
      variables: [Variable<int>(now)],
      readsFrom: {folders, vocabulary, srsProgress},
    ).watch().map((rows) {
      return rows.map((row) {
        return FolderWithCount(
          folder: Folder(
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            description: row.readNullable<String>('description'),
            color: row.read<String>('color'),
            createdAt: row.read<int>('created_at'),
          ),
          totalWords: row.read<int>('total_words'),
          unlearnedCount: row.read<int>('unlearned_count'),
          dueCount: row.read<int>('due_count'),
          lv6Count: row.read<int>('lv6_count'),
        );
      }).toList();
    });
  }
}

@DriftAccessor(tables: [Vocabulary, SrsProgress])
class VocabularyDao extends DatabaseAccessor<AppDatabase>
    with _$VocabularyDaoMixin {
  VocabularyDao(super.db);

  Future<int> insertVocab(VocabularyCompanion vocab) {
    return transaction(() async {
      final vocabId = await into(vocabulary).insert(vocab);
      await insertProgressForVocab(vocabId);
      return vocabId;
    });
  }

  Future<bool> updateVocab(VocabularyCompanion vocab) {
    return update(vocabulary).replace(vocab);
  }

  Future<int> deleteVocab(int id) {
    return (delete(vocabulary)..where((tbl) => tbl.id.equals(id))).go();
  }

  Stream<List<VocabWithProgress>> watchVocabByFolder(
    int folderId, {
    VocabSortMode sortMode = VocabSortMode.newest,
    String searchQuery = '',
  }) {
    final query = _vocabWithProgressQuery(
      folderId: folderId,
      sortMode: sortMode,
      searchQuery: searchQuery,
    );
    return query.watch();
  }

  Stream<List<VocabWithProgress>> watchFavoriteVocab(int folderId) {
    final query = _vocabWithProgressQuery(
      folderId: folderId,
      onlyFavorites: true,
      sortMode: VocabSortMode.newest,
    );
    return query.watch();
  }

  Stream<bool> hasFavorites(int folderId) {
    return (select(vocabulary)
          ..where((tbl) => tbl.folderId.equals(folderId))
          ..where((tbl) => tbl.isFavorite.equals(true))
          ..limit(1))
        .watch()
        .map((rows) => rows.isNotEmpty);
  }

  Future<List<VocabWithProgress>> searchVocab(int folderId, String query) {
    return _vocabWithProgressQuery(
      folderId: folderId,
      searchQuery: query,
      sortMode: VocabSortMode.newest,
    ).get();
  }

  Future<VocabWithProgress?> getVocabById(int id) {
    final query = select(vocabulary).join([
      innerJoin(srsProgress, srsProgress.vocabId.equalsExp(vocabulary.id)),
    ])
      ..where(vocabulary.id.equals(id));

    return query
        .map(
          (row) => VocabWithProgress(
            vocab: row.readTable(vocabulary),
            progress: row.readTable(srsProgress),
          ),
        )
        .getSingleOrNull();
  }

  Future<int> insertOrIgnoreVocab(VocabularyCompanion vocab) {
    return into(vocabulary).insert(vocab, mode: InsertMode.insertOrIgnore);
  }

  Future<int> upsertVocab(VocabularyCompanion vocab) {
    return into(vocabulary).insertOnConflictUpdate(vocab);
  }

  Future<void> toggleFavorite(int vocabId) async {
    final current = await (select(vocabulary)
          ..where((tbl) => tbl.id.equals(vocabId)))
        .getSingle();
    await (update(vocabulary)..where((tbl) => tbl.id.equals(vocabId))).write(
      VocabularyCompanion(isFavorite: Value(!current.isFavorite)),
    );
  }

  Future<int> updateAudioPath(int vocabId, String? path) {
    return (update(vocabulary)..where((tbl) => tbl.id.equals(vocabId))).write(
      VocabularyCompanion(audioPath: Value(path)),
    );
  }

  Selectable<VocabWithProgress> _vocabWithProgressQuery({
    required int folderId,
    required VocabSortMode sortMode,
    String searchQuery = '',
    bool onlyFavorites = false,
  }) {
    final query = select(vocabulary).join([
      innerJoin(srsProgress, srsProgress.vocabId.equalsExp(vocabulary.id)),
    ])
      ..where(vocabulary.folderId.equals(folderId));

    if (onlyFavorites) {
      query.where(vocabulary.isFavorite.equals(true));
    }

    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isNotEmpty) {
      final pattern = '%$trimmedQuery%';
      query.where(
        vocabulary.kanji.like(pattern) |
            vocabulary.kana.like(pattern) |
            vocabulary.romaji.like(pattern) |
            vocabulary.meaning.like(pattern) |
            vocabulary.note.like(pattern),
      );
    }

    switch (sortMode) {
      case VocabSortMode.newest:
        query.orderBy([OrderingTerm.desc(vocabulary.createdAt)]);
      case VocabSortMode.oldest:
        query.orderBy([OrderingTerm.asc(vocabulary.createdAt)]);
      case VocabSortMode.dueTime:
        query.orderBy([OrderingTerm.asc(srsProgress.nextReviewAt)]);
    }

    return query.map(
      (row) => VocabWithProgress(
        vocab: row.readTable(vocabulary),
        progress: row.readTable(srsProgress),
      ),
    );
  }

  Future<void> insertProgressForVocab(int vocabId) {
    return into(srsProgress).insert(
      SrsProgressCompanion.insert(
        vocabId: vocabId,
        level: const Value(SrsConstants.unlearnedLevel),
        intervalDays: const Value(0),
        nextReviewAt: 0,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }
}

@DriftAccessor(tables: [Vocabulary, SrsProgress])
class SrsProgressDao extends DatabaseAccessor<AppDatabase>
    with _$SrsProgressDaoMixin {
  SrsProgressDao(super.db);

  Future<int> insertProgress(SrsProgressCompanion progress) {
    return into(srsProgress).insert(progress);
  }

  Future<bool> updateProgress(SrsProgressCompanion progress) {
    return update(srsProgress).replace(progress);
  }

  Future<int> updateProgressByVocabId(
    int vocabId,
    SrsProgressCompanion progress,
  ) {
    return (update(srsProgress)..where((tbl) => tbl.vocabId.equals(vocabId)))
        .write(progress);
  }

  Stream<List<VocabWithProgress>> watchDueWords({int? folderId}) {
    final now = _nowSeconds();
    final query = _sessionQuery(
      due: true,
      now: now,
      folderId: folderId,
    );
    return query.watch();
  }

  Future<int> getDueCount({int? folderId, bool favoritesOnly = false}) {
    final now = _nowSeconds();
    final buffer = StringBuffer(
      '''
      SELECT COUNT(v.id) AS due_count
      FROM vocabulary v
      INNER JOIN srs_progress sp ON sp.vocab_id = v.id
      WHERE sp.level > 0 AND sp.next_review_at <= ?
      ''',
    );
    final variables = <Variable>[Variable<int>(now)];

    if (folderId != null) {
      buffer.write(' AND v.folder_id = ?');
      variables.add(Variable<int>(folderId));
    }
    if (favoritesOnly) {
      buffer.write(' AND v.is_favorite = 1');
    }

    return customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {vocabulary, srsProgress},
    ).map((row) => row.read<int>('due_count')).getSingle();
  }

  Future<int> getUnlearnedCount({int? folderId}) {
    final query = selectOnly(srsProgress)
      ..addColumns([srsProgress.id.count()])
      ..where(srsProgress.level.equals(SrsConstants.unlearnedLevel));
    if (folderId != null) {
      query.join([
        innerJoin(vocabulary, vocabulary.id.equalsExp(srsProgress.vocabId)),
      ]);
      query.where(vocabulary.folderId.equals(folderId));
    }
    return query
        .map((row) => row.read(srsProgress.id.count()) ?? 0)
        .getSingle();
  }

  Future<List<VocabWithProgress>> getNewVocabForLearning({
    required int folderId,
    required int limit,
    List<int> excludeIds = const [],
  }) {
    final query = select(vocabulary).join([
      innerJoin(srsProgress, srsProgress.vocabId.equalsExp(vocabulary.id)),
    ])
      ..where(vocabulary.folderId.equals(folderId))
      ..where(srsProgress.level.equals(SrsConstants.unlearnedLevel));
    if (excludeIds.isNotEmpty) {
      query.where(vocabulary.id.isNotIn(excludeIds));
    }
    query
      ..orderBy([
        OrderingTerm.asc(srsProgress.lastReviewedAt.isNull()),
        OrderingTerm.asc(srsProgress.lastReviewedAt),
        OrderingTerm.asc(vocabulary.createdAt),
      ])
      ..limit(limit);
    return query
        .map(
          (row) => VocabWithProgress(
            vocab: row.readTable(vocabulary),
            progress: row.readTable(srsProgress),
          ),
        )
        .get();
  }

  Future<List<VocabWithProgress>> getLearnedVocabForDistractors({
    int? folderId,
    required int limit,
    List<int> excludeIds = const [],
  }) {
    final query = select(vocabulary).join([
      innerJoin(srsProgress, srsProgress.vocabId.equalsExp(vocabulary.id)),
    ])
      ..where(srsProgress.level.isBiggerThanValue(SrsConstants.unlearnedLevel));
    if (folderId != null) {
      query.where(vocabulary.folderId.equals(folderId));
    }
    if (excludeIds.isNotEmpty) {
      query.where(vocabulary.id.isNotIn(excludeIds));
    }
    query
      ..orderBy([OrderingTerm.asc(srsProgress.lastReviewedAt)])
      ..limit(limit);
    return query
        .map(
          (row) => VocabWithProgress(
            vocab: row.readTable(vocabulary),
            progress: row.readTable(srsProgress),
          ),
        )
        .get();
  }

  Future<SrsProgressEntry?> getProgressByVocabId(int vocabId) {
    return (select(srsProgress)..where((tbl) => tbl.vocabId.equals(vocabId)))
        .getSingleOrNull();
  }

  Stream<LevelStats> watchLevelStats({int? folderId}) {
    final buffer = StringBuffer(
      '''
      SELECT
        COUNT(v.id) AS total_words,
        COALESCE(SUM(CASE WHEN sp.level = 1 THEN 1 ELSE 0 END), 0) AS lv1_count,
        COALESCE(SUM(CASE WHEN sp.level = 2 THEN 1 ELSE 0 END), 0) AS lv2_count,
        COALESCE(SUM(CASE WHEN sp.level = 3 THEN 1 ELSE 0 END), 0) AS lv3_count,
        COALESCE(SUM(CASE WHEN sp.level = 4 THEN 1 ELSE 0 END), 0) AS lv4_count,
        COALESCE(SUM(CASE WHEN sp.level = 5 THEN 1 ELSE 0 END), 0) AS lv5_count,
        COALESCE(SUM(CASE WHEN sp.level = 6 THEN 1 ELSE 0 END), 0) AS lv6_count
      FROM vocabulary v
      INNER JOIN srs_progress sp ON sp.vocab_id = v.id
      ''',
    );
    final variables = <Variable>[];

    if (folderId != null) {
      buffer.write(' WHERE v.folder_id = ?');
      variables.add(Variable<int>(folderId));
    }

    return customSelect(
      buffer.toString(),
      variables: variables,
      readsFrom: {vocabulary, srsProgress},
    ).watchSingle().map(
          (row) => LevelStats(
            totalWords: row.read<int>('total_words'),
            levelCounts: {
              for (var level = SrsConstants.minLevel;
                  level <= SrsConstants.maxLevel;
                  level++)
                level: row.read<int>('lv${level}_count'),
            },
          ),
        );
  }

  Stream<List<VocabWithProgress>> watchProgressByFolder(int folderId) {
    return _sessionQuery(folderId: folderId).watch();
  }

  Future<List<VocabWithProgress>> getDueVocabForSession({
    int? folderId,
    required int limit,
    List<int> excludeIds = const [],
    bool favoritesOnly = false,
  }) {
    final now = _nowSeconds();
    return _sessionQuery(
      due: true,
      now: now,
      folderId: folderId,
      limit: limit,
      excludeIds: excludeIds,
      favoritesOnly: favoritesOnly,
    ).get();
  }

  Future<List<VocabWithProgress>> getFallbackVocabForSession({
    int? folderId,
    required int limit,
    List<int> excludeIds = const [],
    bool favoritesOnly = false,
  }) {
    final now = _nowSeconds();
    return _sessionQuery(
      fallback: true,
      now: now,
      folderId: folderId,
      limit: limit,
      excludeIds: excludeIds,
      favoritesOnly: favoritesOnly,
    ).get();
  }

  Future<List<VocabWithProgress>> getNonDueVocabForSession({
    int? folderId,
    required int limit,
    List<int> excludeIds = const [],
    bool favoritesOnly = false,
  }) {
    return getFallbackVocabForSession(
      folderId: folderId,
      limit: limit,
      excludeIds: excludeIds,
      favoritesOnly: favoritesOnly,
    );
  }

  Selectable<VocabWithProgress> _sessionQuery({
    int? folderId,
    bool? due,
    bool fallback = false,
    int? now,
    int? limit,
    List<int> excludeIds = const [],
    bool favoritesOnly = false,
  }) {
    final query = select(vocabulary).join([
      innerJoin(srsProgress, srsProgress.vocabId.equalsExp(vocabulary.id)),
    ]);

    if (folderId != null) {
      query.where(vocabulary.folderId.equals(folderId));
    }

    if (favoritesOnly) {
      query.where(vocabulary.isFavorite.equals(true));
    }

    if (due != null) {
      final currentTime = now ?? _nowSeconds();
      query.where(
        srsProgress.level.isBiggerThanValue(SrsConstants.unlearnedLevel) &
            (due
                ? srsProgress.nextReviewAt.isSmallerOrEqualValue(currentTime)
                : srsProgress.nextReviewAt.isBiggerThanValue(currentTime)),
      );
    }

    if (fallback) {
      final currentTime = now ?? _nowSeconds();
      query.where(
        srsProgress.level.isBiggerThanValue(SrsConstants.unlearnedLevel) &
            srsProgress.nextReviewAt.isBiggerThanValue(currentTime),
      );
    }

    if (excludeIds.isNotEmpty) {
      query.where(vocabulary.id.isNotIn(excludeIds));
    }

    query.orderBy(
      fallback
          ? [
              OrderingTerm(
                expression: srsProgress.lastReviewedAt.isNull(),
                mode: OrderingMode.desc,
              ),
              OrderingTerm.asc(srsProgress.lastReviewedAt),
              OrderingTerm.asc(srsProgress.nextReviewAt),
            ]
          : [OrderingTerm.asc(srsProgress.nextReviewAt)],
    );

    if (limit != null) {
      query.limit(limit);
    }

    return query.map(
      (row) => VocabWithProgress(
        vocab: row.readTable(vocabulary),
        progress: row.readTable(srsProgress),
      ),
    );
  }
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<AppSettings> getSettings() async {
    await initSettings();
    return select(settings).getSingle();
  }

  Stream<AppSettings> watchSettings() async* {
    await initSettings();
    yield* select(settings).watchSingle();
  }

  Future<int> updateSettings(SettingsCompanion settingsCompanion) {
    return (update(settings)..where((tbl) => tbl.id.equals(1))).write(
      settingsCompanion,
    );
  }

  Future<int> updateThemeMode(String themeMode) {
    return updateSettings(SettingsCompanion(themeMode: Value(themeMode)));
  }

  Future<void> initSettings() async {
    await into(settings).insert(
      const SettingsCompanion(id: Value(1)),
      mode: InsertMode.insertOrIgnore,
    );
    final currentSettings =
        await (select(settings)..where((tbl) => tbl.id.equals(1))).getSingle();
    if (!currentSettings.defaultKanaSeeded) {
      await db.seedDefaultKanaFolders();
      await updateSettings(
        const SettingsCompanion(defaultKanaSeeded: Value(true)),
      );
    }
  }
}

@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
}

@Riverpod(keepAlive: true)
FolderDao folderDao(FolderDaoRef ref) {
  return ref.watch(appDatabaseProvider).folderDao;
}

@Riverpod(keepAlive: true)
VocabularyDao vocabularyDao(VocabularyDaoRef ref) {
  return ref.watch(appDatabaseProvider).vocabularyDao;
}

@Riverpod(keepAlive: true)
SrsProgressDao srsProgressDao(SrsProgressDaoRef ref) {
  return ref.watch(appDatabaseProvider).srsProgressDao;
}

@Riverpod(keepAlive: true)
SettingsDao settingsDao(SettingsDaoRef ref) {
  return ref.watch(appDatabaseProvider).settingsDao;
}
