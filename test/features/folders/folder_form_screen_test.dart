import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/folders/domain/folder_repository.dart';
import 'package:jvocab/features/folders/presentation/folder_form_screen.dart';
import 'package:jvocab/features/folders/presentation/providers/folder_provider.dart';
import 'package:jvocab/features/import_export/domain/excel_vocab_models.dart';
import 'package:jvocab/features/import_export/domain/import_export_repository.dart';
import 'package:jvocab/features/import_export/presentation/providers/import_export_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('folder controller returns the created folder id', () async {
    final folderRepository = _FakeFolderRepository();
    final container = ProviderContainer(
      overrides: [
        folderRepositoryProvider.overrideWithValue(folderRepository),
      ],
    );
    addTearDown(container.dispose);

    final id =
        await container.read(folderControllerProvider.notifier).createFolder(
              name: ' N5 ',
              description: ' verbs ',
              color: '#6366F1',
            );

    expect(id, 'folder-new');
    expect(folderRepository.createCallCount, 1);
    expect(folderRepository.createdName, ' N5 ');
  });

  testWidgets('new folder form imports selected Excel into the created folder',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final folderRepository = _FakeFolderRepository();
    final importRepository = _FakeImportExportRepository(
      preview: _validPreview,
      importResult: const ExcelImportResult(
        inserted: 1,
        updated: 0,
        skipped: 0,
        failed: 0,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          folderRepositoryProvider.overrideWithValue(folderRepository),
          importExportRepositoryProvider.overrideWithValue(importRepository),
        ],
        child: const MaterialApp(home: FolderFormScreen()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên bộ từ'),
      'JLPT N5',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Chọn file .xlsx'));
    await tester.pumpAndSettle();
    expect(find.text('valid.xlsx'), findsOneWidget);
    expect(find.text('たべる'), findsOneWidget);

    final saveButton = find.byKey(const ValueKey('folder-form-save-button'));
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(folderRepository.createCallCount, 1);
    expect(folderRepository.createdName, 'JLPT N5');
    expect(importRepository.importCallCount, 1);
    expect(importRepository.importedFolderId, 'folder-new');
    expect(importRepository.importedPreview, _validPreview);
    expect(importRepository.importedStrategy, DuplicateStrategy.skip);
    expect(
      find.text('Đã tạo bộ từ và import: thêm 1, bỏ qua 0, lỗi 0.'),
      findsOneWidget,
    );
  });

  testWidgets('new folder form does not create a folder for invalid Excel',
      (tester) async {
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final folderRepository = _FakeFolderRepository();
    final importRepository = _FakeImportExportRepository(
      preview: _invalidPreview,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          folderRepositoryProvider.overrideWithValue(folderRepository),
          importExportRepositoryProvider.overrideWithValue(importRepository),
        ],
        child: const MaterialApp(home: FolderFormScreen()),
      ),
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tên bộ từ'),
      'JLPT N5',
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'Chọn file .xlsx'));
    await tester.pumpAndSettle();

    final saveButton = find.byKey(const ValueKey('folder-form-save-button'));
    await tester.scrollUntilVisible(
      saveButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(folderRepository.createCallCount, 0);
    expect(importRepository.importCallCount, 0);
    expect(
      find.text('File Excel chưa có dòng hợp lệ để import.'),
      findsOneWidget,
    );
  });
}

const _validPreview = ExcelImportPreview(
  fileName: 'valid.xlsx',
  rows: [
    ExcelVocabRow(
      rowNumber: 2,
      kanji: '食べる',
      kana: 'たべる',
      romaji: 'taberu',
      meaning: 'ăn',
    ),
  ],
);

const _invalidPreview = ExcelImportPreview(
  fileName: 'invalid.xlsx',
  rows: [
    ExcelVocabRow(
      rowNumber: 2,
      kana: '',
      romaji: '',
      meaning: '',
      error: 'kana bắt buộc',
    ),
  ],
);

class _FakeFolderRepository extends FolderRepository {
  _FakeFolderRepository() : super(_FakeCloudStore());

  int createCallCount = 0;
  String? createdName;

  @override
  Future<List<FolderWithCount>> getFolders() async => const [];

  @override
  Future<String> createFolder({
    required String name,
    required String color,
    String? description,
  }) async {
    createCallCount++;
    createdName = name;
    return 'folder-new';
  }
}

class _FakeImportExportRepository extends ImportExportRepository {
  _FakeImportExportRepository({
    required this.preview,
    this.importResult = const ExcelImportResult(
      inserted: 0,
      updated: 0,
      skipped: 0,
      failed: 0,
    ),
  }) : super(store: _FakeCloudStore());

  final ExcelImportPreview preview;
  final ExcelImportResult importResult;
  int importCallCount = 0;
  String? importedFolderId;
  ExcelImportPreview? importedPreview;
  DuplicateStrategy? importedStrategy;

  @override
  Future<ExcelImportPreview?> pickPreviewForNewFolder() async => preview;

  @override
  Future<ExcelImportResult> importRows({
    required String folderId,
    required ExcelImportPreview preview,
    required DuplicateStrategy duplicateStrategy,
  }) async {
    importCallCount++;
    importedFolderId = folderId;
    importedPreview = preview;
    importedStrategy = duplicateStrategy;
    return importResult;
  }
}

class _FakeCloudStore extends CloudStore {
  _FakeCloudStore()
      : super(
          SupabaseClient(
            'https://example.supabase.co',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );
}
