enum VocabSortMode { newest, oldest, dueTime }

int _seconds(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final date = DateTime.tryParse(value.toString());
  return date == null ? fallback : date.millisecondsSinceEpoch ~/ 1000;
}

String _iso(int seconds) =>
    DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true)
        .toIso8601String();

class Folder {
  const Folder({
    required this.id,
    required this.name,
    required this.color,
    required this.createdAt,
    this.description,
    this.sortOrder = 0,
    this.updatedAt = 0,
  });

  factory Folder.fromJson(Map<String, dynamic> json) => Folder(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        color: json['color'] as String? ?? '#6366F1',
        sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
        createdAt: _seconds(json['created_at']),
        updatedAt: _seconds(json['updated_at']),
      );

  final String id;
  final String name;
  final String? description;
  final String color;
  final int sortOrder;
  final int createdAt;
  final int updatedAt;
}

class VocabularyEntry {
  const VocabularyEntry({
    required this.id,
    required this.folderId,
    required this.kana,
    required this.romaji,
    required this.meaning,
    required this.isFavorite,
    required this.createdAt,
    this.kanji,
    this.pitchAccent,
    this.example,
    this.note,
    this.updatedAt = 0,
  });

  factory VocabularyEntry.fromJson(Map<String, dynamic> json) =>
      VocabularyEntry(
        id: json['id'] as String,
        folderId: json['folder_id'] as String,
        kanji: json['kanji'] as String?,
        kana: json['kana'] as String,
        romaji: json['romaji'] as String,
        meaning: json['meaning'] as String,
        pitchAccent: json['pitch_accent'] as String?,
        example: json['example'] as String?,
        note: json['note'] as String?,
        isFavorite: json['is_favorite'] as bool? ?? false,
        createdAt: _seconds(json['created_at']),
        updatedAt: _seconds(json['updated_at']),
      );

  final String id;
  final String folderId;
  final String? kanji;
  final String kana;
  final String romaji;
  final String meaning;
  final String? pitchAccent;
  final String? example;
  final String? note;
  final bool isFavorite;
  final int createdAt;
  final int updatedAt;
}

class SrsProgressEntry {
  const SrsProgressEntry({
    required this.vocabId,
    required this.level,
    required this.intervalDays,
    required this.nextReviewAt,
    required this.correctCount,
    required this.wrongCount,
    this.lastReviewedAt,
    this.updatedAt = 0,
  });

  factory SrsProgressEntry.fromJson(Map<String, dynamic> json) =>
      SrsProgressEntry(
        vocabId: json['vocab_id'] as String,
        level: (json['level'] as num?)?.toInt() ?? 0,
        intervalDays: (json['interval_days'] as num?)?.toDouble() ?? 0,
        nextReviewAt: _seconds(json['next_review_at']),
        correctCount: (json['correct_count'] as num?)?.toInt() ?? 0,
        wrongCount: (json['wrong_count'] as num?)?.toInt() ?? 0,
        lastReviewedAt: json['last_reviewed_at'] == null
            ? null
            : _seconds(json['last_reviewed_at']),
        updatedAt: _seconds(json['updated_at']),
      );

  final String vocabId;
  final int level;
  final double intervalDays;
  final int nextReviewAt;
  final int correctCount;
  final int wrongCount;
  final int? lastReviewedAt;
  final int updatedAt;

  Map<String, dynamic> toCloudJson() => {
        'level': level,
        'interval_days': intervalDays,
        'next_review_at': _iso(nextReviewAt),
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'last_reviewed_at':
            lastReviewedAt == null ? null : _iso(lastReviewedAt!),
      };

  SrsProgressEntry copyWith({
    int? level,
    double? intervalDays,
    int? nextReviewAt,
    int? correctCount,
    int? wrongCount,
    int? lastReviewedAt,
  }) =>
      SrsProgressEntry(
        vocabId: vocabId,
        level: level ?? this.level,
        intervalDays: intervalDays ?? this.intervalDays,
        nextReviewAt: nextReviewAt ?? this.nextReviewAt,
        correctCount: correctCount ?? this.correctCount,
        wrongCount: wrongCount ?? this.wrongCount,
        lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
        updatedAt: updatedAt,
      );
}

class VocabWithProgress {
  const VocabWithProgress({required this.vocab, required this.progress});
  final VocabularyEntry vocab;
  final SrsProgressEntry progress;
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

class VocabSearchResult {
  const VocabSearchResult({required this.item, required this.folder});
  final VocabWithProgress item;
  final Folder folder;
}

class LevelStats {
  const LevelStats({required this.totalWords, required this.levelCounts});
  final int totalWords;
  final Map<int, int> levelCounts;
  int countForLevel(int level) => levelCounts[level] ?? 0;
  int get learnedWords =>
      levelCounts.entries.where((entry) => entry.key > 0).fold(
            0,
            (total, entry) => total + entry.value,
          );
}

class AppSettings {
  const AppSettings({
    this.notifyEnabled = false,
    this.notifyHour = 8,
    this.notifyMinute = 0,
    this.sessionSize = 10,
    this.quizDirection = 'ja_to_vi',
    this.quizListenCount = 1,
    this.quizReadCount = 1,
    this.quizWriteCount = 1,
    this.quizChooseWordCount = 1,
    this.quizChooseMeaningCount = 1,
    this.quizRetryLimit = 2,
    this.newWordSessionSize = 5,
    this.newWordListenCount = 1,
    this.newWordWriteCount = 1,
    this.newWordChooseWordCount = 1,
    this.newWordChooseMeaningCount = 1,
    this.quizJapaneseScript = 'kanji',
    this.themeMode = 'light',
    this.srsLevel1IntervalDays = 2 / 24,
    this.srsLevel2IntervalDays = 1,
    this.srsLevel3IntervalDays = 2,
    this.srsLevel4IntervalDays = 3,
    this.srsLevel5IntervalDays = 5,
    this.srsLevel6IntervalDays = 8,
    this.flashcardShowKana = true,
    this.flashcardShowRomaji = true,
  });

  factory AppSettings.fromCloud(
    Map<String, dynamic> learning,
    Map<String, dynamic>? device,
  ) =>
      AppSettings(
        notifyEnabled: device?['notify_enabled'] as bool? ?? false,
        notifyHour: (device?['notify_hour'] as num?)?.toInt() ?? 8,
        notifyMinute: (device?['notify_minute'] as num?)?.toInt() ?? 0,
        themeMode: device?['theme_mode'] as String? ?? 'light',
        sessionSize: (learning['session_size'] as num?)?.toInt() ?? 10,
        quizDirection: learning['quiz_direction'] as String? ?? 'ja_to_vi',
        quizListenCount: (learning['quiz_listen_count'] as num?)?.toInt() ?? 1,
        quizReadCount: (learning['quiz_read_count'] as num?)?.toInt() ?? 1,
        quizWriteCount: (learning['quiz_write_count'] as num?)?.toInt() ?? 1,
        quizChooseWordCount:
            (learning['quiz_choose_word_count'] as num?)?.toInt() ?? 1,
        quizChooseMeaningCount:
            (learning['quiz_choose_meaning_count'] as num?)?.toInt() ?? 1,
        quizRetryLimit: (learning['quiz_retry_limit'] as num?)?.toInt() ?? 2,
        newWordSessionSize:
            (learning['new_word_session_size'] as num?)?.toInt() ?? 5,
        newWordListenCount:
            (learning['new_word_listen_count'] as num?)?.toInt() ?? 1,
        newWordWriteCount:
            (learning['new_word_write_count'] as num?)?.toInt() ?? 1,
        newWordChooseWordCount:
            (learning['new_word_choose_word_count'] as num?)?.toInt() ?? 1,
        newWordChooseMeaningCount:
            (learning['new_word_choose_meaning_count'] as num?)?.toInt() ?? 1,
        quizJapaneseScript:
            learning['quiz_japanese_script'] as String? ?? 'kanji',
        srsLevel1IntervalDays:
            (learning['srs_level_1_interval_days'] as num?)?.toDouble() ??
                2 / 24,
        srsLevel2IntervalDays:
            (learning['srs_level_2_interval_days'] as num?)?.toDouble() ?? 1,
        srsLevel3IntervalDays:
            (learning['srs_level_3_interval_days'] as num?)?.toDouble() ?? 2,
        srsLevel4IntervalDays:
            (learning['srs_level_4_interval_days'] as num?)?.toDouble() ?? 3,
        srsLevel5IntervalDays:
            (learning['srs_level_5_interval_days'] as num?)?.toDouble() ?? 5,
        srsLevel6IntervalDays:
            (learning['srs_level_6_interval_days'] as num?)?.toDouble() ?? 8,
        flashcardShowKana: learning['flashcard_show_kana'] as bool? ?? true,
        flashcardShowRomaji: learning['flashcard_show_romaji'] as bool? ?? true,
      );

  final bool notifyEnabled;
  final int notifyHour;
  final int notifyMinute;
  final int sessionSize;
  final String quizDirection;
  final int quizListenCount;
  final int quizReadCount;
  final int quizWriteCount;
  final int quizChooseWordCount;
  final int quizChooseMeaningCount;
  final int quizRetryLimit;
  final int newWordSessionSize;
  final int newWordListenCount;
  final int newWordWriteCount;
  final int newWordChooseWordCount;
  final int newWordChooseMeaningCount;
  final String quizJapaneseScript;
  final String themeMode;
  final double srsLevel1IntervalDays;
  final double srsLevel2IntervalDays;
  final double srsLevel3IntervalDays;
  final double srsLevel4IntervalDays;
  final double srsLevel5IntervalDays;
  final double srsLevel6IntervalDays;
  final bool flashcardShowKana;
  final bool flashcardShowRomaji;

  AppSettings copyWith({
    bool? notifyEnabled,
    int? notifyHour,
    int? notifyMinute,
    int? sessionSize,
    String? quizDirection,
    int? quizListenCount,
    int? quizReadCount,
    int? quizWriteCount,
    int? quizChooseWordCount,
    int? quizChooseMeaningCount,
    int? quizRetryLimit,
    int? newWordSessionSize,
    int? newWordListenCount,
    int? newWordWriteCount,
    int? newWordChooseWordCount,
    int? newWordChooseMeaningCount,
    String? quizJapaneseScript,
    String? themeMode,
    double? srsLevel1IntervalDays,
    double? srsLevel2IntervalDays,
    double? srsLevel3IntervalDays,
    double? srsLevel4IntervalDays,
    double? srsLevel5IntervalDays,
    double? srsLevel6IntervalDays,
    bool? flashcardShowKana,
    bool? flashcardShowRomaji,
  }) =>
      AppSettings(
        notifyEnabled: notifyEnabled ?? this.notifyEnabled,
        notifyHour: notifyHour ?? this.notifyHour,
        notifyMinute: notifyMinute ?? this.notifyMinute,
        sessionSize: sessionSize ?? this.sessionSize,
        quizDirection: quizDirection ?? this.quizDirection,
        quizListenCount: quizListenCount ?? this.quizListenCount,
        quizReadCount: quizReadCount ?? this.quizReadCount,
        quizWriteCount: quizWriteCount ?? this.quizWriteCount,
        quizChooseWordCount: quizChooseWordCount ?? this.quizChooseWordCount,
        quizChooseMeaningCount:
            quizChooseMeaningCount ?? this.quizChooseMeaningCount,
        quizRetryLimit: quizRetryLimit ?? this.quizRetryLimit,
        newWordSessionSize: newWordSessionSize ?? this.newWordSessionSize,
        newWordListenCount: newWordListenCount ?? this.newWordListenCount,
        newWordWriteCount: newWordWriteCount ?? this.newWordWriteCount,
        newWordChooseWordCount:
            newWordChooseWordCount ?? this.newWordChooseWordCount,
        newWordChooseMeaningCount:
            newWordChooseMeaningCount ?? this.newWordChooseMeaningCount,
        quizJapaneseScript: quizJapaneseScript ?? this.quizJapaneseScript,
        themeMode: themeMode ?? this.themeMode,
        srsLevel1IntervalDays:
            srsLevel1IntervalDays ?? this.srsLevel1IntervalDays,
        srsLevel2IntervalDays:
            srsLevel2IntervalDays ?? this.srsLevel2IntervalDays,
        srsLevel3IntervalDays:
            srsLevel3IntervalDays ?? this.srsLevel3IntervalDays,
        srsLevel4IntervalDays:
            srsLevel4IntervalDays ?? this.srsLevel4IntervalDays,
        srsLevel5IntervalDays:
            srsLevel5IntervalDays ?? this.srsLevel5IntervalDays,
        srsLevel6IntervalDays:
            srsLevel6IntervalDays ?? this.srsLevel6IntervalDays,
        flashcardShowKana: flashcardShowKana ?? this.flashcardShowKana,
        flashcardShowRomaji: flashcardShowRomaji ?? this.flashcardShowRomaji,
      );
}

String secondsToCloudTimestamp(int seconds) => _iso(seconds);
