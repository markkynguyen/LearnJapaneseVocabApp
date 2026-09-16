import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/audio/audio_service.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/home/presentation/home_screen.dart';
import 'package:jvocab/features/home/presentation/providers/home_provider.dart';
import 'package:jvocab/features/kanji/domain/kanji_models.dart';
import 'package:jvocab/features/kanji/presentation/providers/kanji_providers.dart';
import 'package:jvocab/features/vocab/presentation/providers/vocab_list_provider.dart';
import 'package:jvocab/features/vocab/presentation/widgets/pitch_accent_text.dart';
import 'package:jvocab/features/vocab/presentation/widgets/vocabulary_study_card.dart';

void main() {
  testWidgets('home search debounces suggestions and opens shared detail card',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final audio = _FakeAudioService();
    final result = _result();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          greetingProvider.overrideWith((ref) => 'Xin chào'),
          totalDueCountProvider.overrideWith((ref) => 0),
          totalLevelStatsProvider.overrideWith(
            (ref) => const LevelStats(totalWords: 1, levelCounts: {1: 1}),
          ),
          kanjiSnapshotProvider.overrideWith((ref) => _kanjiSnapshot()),
          homeVocabSuggestionsProvider('tab').overrideWith(
            (ref) => [result],
          ),
          audioServiceProvider.overrideWith((ref) => audio),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.textContaining('Chào buổi'), findsNothing);
    expect(find.textContaining('Hôm nay bạn có'), findsNothing);
    expect(find.text('Thống kê học tập của bạn'), findsOneWidget);
    expect(find.text('Kanji'), findsOneWidget);
    expect(find.text('Bộ thủ'), findsOneWidget);
    expect(find.text('đã học / tổng số'), findsNothing);
    expect(find.text('Hán tự khác nhau'), findsNothing);
    expect(find.text('Bộ thủ đã gặp'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Kanji: 3',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Bộ thủ: 2',
      ),
      findsOneWidget,
    );
    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText ==
              'Tra kanji, kana, romaji hoặc nghĩa...',
    );
    await tester.enterText(searchField, 'tab');
    await tester.pump(const Duration(milliseconds: 249));
    expect(find.text('食べる'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('食べる'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is PitchAccentText &&
            widget.kana == 'たべる' &&
            widget.pattern == 'HHL',
      ),
      findsOneWidget,
    );
    expect(find.text('ăn'), findsOneWidget);
    expect(find.text('Động từ N5'), findsOneWidget);

    await tester.tap(find.text('食べる'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(VocabularyStudyCard), findsOneWidget);
    expect(
      tester
          .widget<VocabularyStudyCard>(find.byType(VocabularyStudyCard))
          .framed,
      isFalse,
    );
    expect(find.widgetWithText(OutlinedButton, 'Giảm 1 level'), findsNothing);
    expect(
      find.widgetWithText(OutlinedButton, 'Reset về level 1'),
      findsNothing,
    );
    expect(audio.spokenVocabIds, isEmpty);

    await tester.tap(find.byTooltip('Phát âm'));
    await tester.pump();
    expect(audio.spokenVocabIds, ['vocab-1']);

    await tester.tap(find.byTooltip('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(find.text('食べる'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home detail confirms and applies manual SRS actions from Lv 2',
      (tester) async {
    final controller = _FakeVocabListController();
    final result = _result(level: 2);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          greetingProvider.overrideWith((ref) => 'Xin chào'),
          totalDueCountProvider.overrideWith((ref) => 0),
          totalLevelStatsProvider.overrideWith(
            (ref) => const LevelStats(totalWords: 1, levelCounts: {2: 1}),
          ),
          kanjiSnapshotProvider.overrideWith((ref) => _kanjiSnapshot()),
          homeVocabSuggestionsProvider('tab').overrideWith((ref) => [result]),
          audioServiceProvider.overrideWith((ref) => _FakeAudioService()),
          vocabListControllerProvider.overrideWith(() => controller),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    final searchField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.hintText ==
              'Tra kanji, kana, romaji hoặc nghĩa...',
    );
    await tester.enterText(searchField, 'tab');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
    await tester.tap(find.text('食べる'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Sửa từ vựng'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Giảm 1 level'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Reset về level 1'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Giảm 1 level'));
    await tester.pumpAndSettle();
    expect(find.text('Giảm 1 level?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();
    expect(controller.minusOneCalls, 0);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Giảm 1 level'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Giảm 1 level'));
    await tester.pumpAndSettle();
    expect(controller.minusOneCalls, 1);
    expect(find.widgetWithText(OutlinedButton, 'Giảm 1 level'), findsNothing);
    expect(
      find.widgetWithText(OutlinedButton, 'Reset về level 1'),
      findsNothing,
    );
  });
}

KanjiSnapshot _kanjiSnapshot() => KanjiSnapshot.fromJson({
      'overview': {
        'last_calculated_at': '2026-09-06T00:00:00Z',
        'total_kanji_count': 3,
        'total_radical_count': 2,
        'total_vocab_scanned': 1,
        'unsupported_kanji_count': 0,
        'component_version': 4,
      },
      'kanji': <Object?>[],
      'radicals': <Object?>[],
      'radical_forms': [
        {
          'id': 87,
          'character': '爪',
          'name_vi': 'Trảo',
          'meaning_vi': 'Móng vuốt',
          'stroke_count': 4,
          'variants': ['爫', '⺤'],
          'positions': <String>[],
          'form': '爫',
          'count': 2,
          'family_count': 5,
          'is_original': false,
          'form_order': 1,
        },
        {
          'id': 87,
          'character': '爪',
          'name_vi': 'Trảo',
          'meaning_vi': 'Móng vuốt',
          'stroke_count': 4,
          'variants': ['爫', '⺤'],
          'positions': <String>[],
          'form': '⺤',
          'count': 3,
          'family_count': 5,
          'is_original': false,
          'form_order': 2,
        },
        {
          'id': 75,
          'character': '木',
          'name_vi': 'Mộc',
          'meaning_vi': 'Cây',
          'stroke_count': 4,
          'variants': <String>[],
          'positions': <String>[],
          'form': '木',
          'count': 1,
          'family_count': 1,
          'is_original': true,
          'form_order': 0,
        },
      ],
    });

class _FakeAudioService extends AudioService {
  final List<String> spokenVocabIds = [];

  @override
  Future<void> speak(VocabularyEntry vocab) async {
    spokenVocabIds.add(vocab.id);
  }

  @override
  Future<void> dispose() async {}
}

class _FakeVocabListController extends VocabListController {
  int minusOneCalls = 0;

  @override
  void build() {}

  @override
  Future<void> manualMinus1(VocabWithProgress item) async {
    minusOneCalls += 1;
  }
}

VocabSearchResult _result({int level = 1}) {
  return VocabSearchResult(
    item: VocabWithProgress(
      vocab: const VocabularyEntry(
        id: 'vocab-1',
        folderId: 'folder-10',
        kanji: '食べる',
        kana: 'たべる',
        romaji: 'taberu',
        meaning: 'ăn',
        pitchAccent: 'HHL',
        example: '毎日ご飯を食べる。',
        note: 'Động từ nhóm 2',
        isFavorite: false,
        createdAt: 0,
      ),
      progress: SrsProgressEntry(
        vocabId: 'vocab-1',
        level: level,
        intervalDays: 1,
        nextReviewAt: 0,
        correctCount: 0,
        wrongCount: 0,
      ),
    ),
    folder: const Folder(
      id: 'folder-10',
      name: 'Động từ N5',
      description: null,
      color: '#6366F1',
      createdAt: 0,
    ),
  );
}
