import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/app_models.dart';

part 'cloud_store.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(SupabaseClientRef ref) =>
    Supabase.instance.client;

@Riverpod(keepAlive: true)
CloudStore cloudStore(CloudStoreRef ref) =>
    CloudStore(ref.watch(supabaseClientProvider));

@riverpod
Future<void> cloudBootstrap(CloudBootstrapRef ref) =>
    ref.watch(cloudStoreProvider).bootstrapUser();

@Riverpod(keepAlive: true)
Future<String> deviceId(DeviceIdRef ref) async {
  final preferences = await SharedPreferences.getInstance();
  const key = 'nana_cloud_device_id';
  final existing = preferences.getString(key);
  if (existing != null && existing.isNotEmpty) return existing;
  final created = const Uuid().v4();
  await preferences.setString(key, created);
  return created;
}

class CloudStore {
  const CloudStore(this._client);
  final SupabaseClient _client;

  User get _user {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('Bạn chưa đăng nhập.');
    return user;
  }

  Future<void> bootstrapUser() async {
    await _client.rpc<void>('bootstrap_current_user');
  }

  Future<List<FolderWithCount>> getFolderSummaries() async {
    final rows = await _client.rpc<List<dynamic>>('get_folder_summaries');
    return rows.map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return FolderWithCount(
        folder: Folder.fromJson(row),
        totalWords: (row['total_words'] as num?)?.toInt() ?? 0,
        unlearnedCount: (row['unlearned_count'] as num?)?.toInt() ?? 0,
        dueCount: (row['due_count'] as num?)?.toInt() ?? 0,
        lv6Count: (row['lv6_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<Folder>> getFolders() async {
    final rows = await _client
        .from('folders')
        .select()
        .order('sort_order')
        .order('created_at');
    return rows.map((row) => Folder.fromJson(row)).toList();
  }

  Future<Folder?> getFolder(String id) async {
    final row =
        await _client.from('folders').select().eq('id', id).maybeSingle();
    return row == null ? null : Folder.fromJson(row);
  }

  Future<String> createFolder({
    required String name,
    required String color,
    String? description,
  }) async {
    final row = await _client
        .from('folders')
        .insert({
          'user_id': _user.id,
          'name': name,
          'description': description,
          'color': color,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateFolder({
    required String id,
    required String name,
    required String color,
    String? description,
  }) =>
      _client.from('folders').update({
        'name': name,
        'description': description,
        'color': color,
      }).eq('id', id);

  Future<void> deleteFolder(String id) =>
      _client.from('folders').delete().eq('id', id);

  Future<void> reorderFolders(List<String> orderedIds) => _client.rpc<void>(
        'reorder_folders',
        params: {'ordered_ids': orderedIds},
      );

  Future<List<VocabWithProgress>> getVocabByFolder(
    String folderId, {
    VocabSortMode sortMode = VocabSortMode.newest,
    String searchQuery = '',
    bool favoritesOnly = false,
  }) async {
    final rows = await _client
        .from('vocabulary')
        .select('*, srs_progress(*)')
        .eq('folder_id', folderId);
    var items = rows.map(_vocabWithProgress).toList();
    if (favoritesOnly) {
      items = items.where((item) => item.vocab.isFavorite).toList();
    }
    final query = searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) {
        final vocab = item.vocab;
        return [
          vocab.kanji,
          vocab.kana,
          vocab.romaji,
          vocab.meaning,
          vocab.note,
        ]
            .whereType<String>()
            .any((value) => value.toLowerCase().contains(query));
      }).toList();
    }
    items.sort(
      (a, b) => switch (sortMode) {
        VocabSortMode.oldest => a.vocab.createdAt.compareTo(b.vocab.createdAt),
        VocabSortMode.dueTime =>
          a.progress.nextReviewAt.compareTo(b.progress.nextReviewAt),
        VocabSortMode.newest => b.vocab.createdAt.compareTo(a.vocab.createdAt),
      },
    );
    return items;
  }

  Future<VocabWithProgress?> getVocab(String id) async {
    final row = await _client
        .from('vocabulary')
        .select('*, srs_progress(*)')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : _vocabWithProgress(row);
  }

  Future<String> createVocab({
    required String folderId,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? example,
    String? note,
  }) async {
    final row = await _client
        .from('vocabulary')
        .insert({
          'user_id': _user.id,
          'folder_id': folderId,
          'kanji': kanji,
          'kana': kana,
          'romaji': romaji,
          'meaning': meaning,
          'pitch_accent': pitchAccent,
          'example': example,
          'note': note,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateVocab({
    required String id,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? example,
    String? note,
  }) =>
      _client.from('vocabulary').update({
        'kanji': kanji,
        'kana': kana,
        'romaji': romaji,
        'meaning': meaning,
        'pitch_accent': pitchAccent,
        'example': example,
        'note': note,
      }).eq('id', id);

  Future<void> deleteVocab(String id) =>
      _client.from('vocabulary').delete().eq('id', id);

  Future<void> toggleFavorite(VocabularyEntry vocab) => _client
      .from('vocabulary')
      .update({'is_favorite': !vocab.isFavorite}).eq('id', vocab.id);

  Future<void> updateProgress(SrsProgressEntry progress) => _client
      .from('srs_progress')
      .update(progress.toCloudJson())
      .eq('vocab_id', progress.vocabId);

  Future<List<VocabSearchResult>> searchAllVocab(
    String query, {
    int limit = 4,
  }) async {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return const [];
    final rows = await _client
        .from('vocabulary')
        .select('*, folders(*), srs_progress(*)')
        .limit(100);
    final results = <VocabSearchResult>[];
    for (final row in rows) {
      final item = _vocabWithProgress(row);
      final values = [
        item.vocab.kanji,
        item.vocab.kana,
        item.vocab.romaji,
        item.vocab.meaning,
        item.vocab.note,
      ].whereType<String>();
      if (!values.any((value) => value.toLowerCase().contains(normalized))) {
        continue;
      }
      final folderRaw = row['folders'];
      if (folderRaw is Map) {
        results.add(
          VocabSearchResult(
            item: item,
            folder: Folder.fromJson(Map<String, dynamic>.from(folderRaw)),
          ),
        );
      }
      if (results.length == limit) break;
    }
    return results;
  }

  Future<LevelStats> getLevelStats({String? folderId}) async {
    final items = folderId == null
        ? await getAllVocab()
        : await getVocabByFolder(folderId);
    final counts = <int, int>{};
    for (final item in items) {
      counts.update(
        item.progress.level,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return LevelStats(totalWords: items.length, levelCounts: counts);
  }

  Future<List<VocabWithProgress>> getAllVocab() async {
    final rows = await _client.from('vocabulary').select('*, srs_progress(*)');
    return rows.map(_vocabWithProgress).toList();
  }

  Future<int> getDueCount({
    String? folderId,
    bool favoritesOnly = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final items = folderId == null
        ? await getAllVocab()
        : await getVocabByFolder(folderId, favoritesOnly: favoritesOnly);
    return items
        .where(
          (item) =>
              item.progress.level > 0 && item.progress.nextReviewAt <= now,
        )
        .length;
  }

  Future<AppSettings> getSettings(String deviceId) async {
    await bootstrapUser();
    final learning = await _client
        .from('user_learning_settings')
        .select()
        .eq('user_id', _user.id)
        .single();
    final device = await _client
        .from('device_preferences')
        .select()
        .eq('user_id', _user.id)
        .eq('device_id', deviceId)
        .maybeSingle();
    return AppSettings.fromCloud(learning, device);
  }

  Future<AppSettings> getLearningSettings() async {
    await bootstrapUser();
    final learning = await _client
        .from('user_learning_settings')
        .select()
        .eq('user_id', _user.id)
        .single();
    return AppSettings.fromCloud(learning, null);
  }

  Future<void> applySrsUpdates(List<SrsProgressEntry> updates) =>
      _client.rpc<void>(
        'apply_srs_updates',
        params: {
          'payload': [
            for (final progress in updates)
              {'vocab_id': progress.vocabId, ...progress.toCloudJson()},
          ],
        },
      );

  Future<Map<String, dynamic>> importVocabulary({
    required String folderId,
    required List<Map<String, dynamic>> rows,
    required String duplicateStrategy,
  }) =>
      _client.rpc<Map<String, dynamic>>(
        'import_vocabulary',
        params: {
          'target_folder_id': folderId,
          'payload': rows,
          'duplicate_strategy': duplicateStrategy,
        },
      );

  Future<void> updateLearningSettings(Map<String, dynamic> values) => _client
      .from('user_learning_settings')
      .update(values)
      .eq('user_id', _user.id);

  Future<void> saveSettings(String deviceId, AppSettings settings) async {
    await Future.wait([
      updateLearningSettings({
        'session_size': settings.sessionSize,
        'quiz_direction': settings.quizDirection,
        'quiz_listen_count': settings.quizListenCount,
        'quiz_read_count': settings.quizReadCount,
        'quiz_write_count': settings.quizWriteCount,
        'quiz_choose_word_count': settings.quizChooseWordCount,
        'quiz_choose_meaning_count': settings.quizChooseMeaningCount,
        'quiz_retry_limit': settings.quizRetryLimit,
        'new_word_session_size': settings.newWordSessionSize,
        'new_word_listen_count': settings.newWordListenCount,
        'new_word_write_count': settings.newWordWriteCount,
        'new_word_choose_word_count': settings.newWordChooseWordCount,
        'new_word_choose_meaning_count': settings.newWordChooseMeaningCount,
        'quiz_japanese_script': settings.quizJapaneseScript,
        'srs_level_1_interval_days': settings.srsLevel1IntervalDays,
        'srs_level_2_interval_days': settings.srsLevel2IntervalDays,
        'srs_level_3_interval_days': settings.srsLevel3IntervalDays,
        'srs_level_4_interval_days': settings.srsLevel4IntervalDays,
        'srs_level_5_interval_days': settings.srsLevel5IntervalDays,
        'srs_level_6_interval_days': settings.srsLevel6IntervalDays,
        'flashcard_show_kana': settings.flashcardShowKana,
        'flashcard_show_romaji': settings.flashcardShowRomaji,
      }),
      updateDevicePreferences(deviceId, {
        'theme_mode': settings.themeMode,
        'notify_enabled': settings.notifyEnabled,
        'notify_hour': settings.notifyHour,
        'notify_minute': settings.notifyMinute,
      }),
    ]);
  }

  Future<void> updateDevicePreferences(
    String deviceId,
    Map<String, dynamic> values,
  ) =>
      _client.from('device_preferences').upsert(
        {
          'user_id': _user.id,
          'device_id': deviceId,
          ...values,
        },
        onConflict: 'user_id,device_id',
      );

  VocabWithProgress _vocabWithProgress(Map<String, dynamic> row) {
    final rawProgress = row['srs_progress'];
    final progressMap = switch (rawProgress) {
      Map() => Map<String, dynamic>.from(rawProgress),
      List() when rawProgress.isNotEmpty =>
        Map<String, dynamic>.from(rawProgress.first as Map),
      _ => <String, dynamic>{'vocab_id': row['id']},
    };
    return VocabWithProgress(
      vocab: VocabularyEntry.fromJson(row),
      progress: SrsProgressEntry.fromJson(progressMap),
    );
  }
}
