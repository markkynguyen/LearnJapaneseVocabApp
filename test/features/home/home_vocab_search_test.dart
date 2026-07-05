import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/audio/audio_service.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/home/presentation/home_screen.dart';
import 'package:jvocab/features/home/presentation/providers/home_provider.dart';
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
}

class _FakeAudioService extends AudioService {
  final List<String> spokenVocabIds = [];

  @override
  Future<void> speak(VocabularyEntry vocab) async {
    spokenVocabIds.add(vocab.id);
  }

  @override
  Future<void> dispose() async {}
}

VocabSearchResult _result() {
  return const VocabSearchResult(
    item: VocabWithProgress(
      vocab: VocabularyEntry(
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
        level: 1,
        intervalDays: 1,
        nextReviewAt: 0,
        correctCount: 0,
        wrongCount: 0,
      ),
    ),
    folder: Folder(
      id: 'folder-10',
      name: 'Động từ N5',
      description: null,
      color: '#6366F1',
      createdAt: 0,
    ),
  );
}
