import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/vocab/domain/vocabulary_repository.dart';
import 'package:jvocab/features/vocab/presentation/providers/vocab_form_provider.dart';
import 'package:jvocab/features/vocab/presentation/vocab_form_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('edit save with changes returns changed result', (tester) async {
    final store = _FakeVocabularyStore();
    Future<VocabEditResult?>? routeResult;

    await _pumpEditLauncher(
      tester,
      store: store,
      onRouteResult: (result) => routeResult = result,
    );
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nghĩa *'),
      'ăn cơm',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    final result = await routeResult;
    expect(result?.vocabId, 'vocab-1');
    expect(result?.changed, isTrue);
    expect(store.updateCount, 1);
    expect(store.updatedMeaning, 'ăn cơm');
  });

  testWidgets('edit save without changes returns unchanged result',
      (tester) async {
    final store = _FakeVocabularyStore();
    Future<VocabEditResult?>? routeResult;

    await _pumpEditLauncher(
      tester,
      store: store,
      onRouteResult: (result) => routeResult = result,
    );
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    final result = await routeResult;
    expect(result?.vocabId, 'vocab-1');
    expect(result?.changed, isFalse);
    expect(store.updateCount, 0);
  });

  testWidgets('back from edit form returns null', (tester) async {
    final store = _FakeVocabularyStore();
    Future<VocabEditResult?>? routeResult;

    await _pumpEditLauncher(
      tester,
      store: store,
      onRouteResult: (result) => routeResult = result,
    );
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(await routeResult, isNull);
    expect(store.updateCount, 0);
  });
}

Future<void> _pumpEditLauncher(
  WidgetTester tester, {
  required _FakeVocabularyStore store,
  required void Function(Future<VocabEditResult?> result) onRouteResult,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vocabularyRepositoryProvider.overrideWith(
          (ref) => VocabularyRepository(store),
        ),
        vocabFormItemProvider('vocab-1').overrideWith(
          (ref) async => _item(),
        ),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () {
                  onRouteResult(
                    Navigator.of(context).push<VocabEditResult>(
                      MaterialPageRoute(
                        builder: (_) => const VocabFormScreen(
                          folderId: 'folder-1',
                          vocabId: 'vocab-1',
                        ),
                      ),
                    ),
                  );
                },
                child: const Text('Mở form'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FakeVocabularyStore extends CloudStore {
  _FakeVocabularyStore()
      : super(
          SupabaseClient(
            'http://localhost',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  int updateCount = 0;
  String? updatedMeaning;

  @override
  Future<void> updateVocab({
    required String id,
    required String kana,
    required String romaji,
    required String meaning,
    String? kanji,
    String? pitchAccent,
    String? ttsText,
    String? example,
    String? note,
  }) async {
    updateCount += 1;
    updatedMeaning = meaning;
  }
}

VocabWithProgress _item() {
  return const VocabWithProgress(
    vocab: VocabularyEntry(
      id: 'vocab-1',
      folderId: 'folder-1',
      kanji: '食べる',
      kana: 'たべる',
      romaji: 'taberu',
      meaning: 'ăn',
      pitchAccent: 'HHL',
      ttsText: 'たべる',
      example: 'ご飯を食べます。',
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
  );
}
