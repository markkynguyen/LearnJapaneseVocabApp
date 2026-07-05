import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/cloud/cloud_store.dart';
import 'package:jvocab/core/models/app_models.dart';
import 'package:jvocab/features/folders/presentation/folder_list_screen.dart';
import 'package:jvocab/features/folders/presentation/widgets/folder_progress_list.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  testWidgets('library progress card opens folder and exposes edit/delete menu',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? openedId;
    FolderWithCount? edited;
    FolderWithCount? deleted;
    const item = FolderWithCount(
      folder: Folder(
        id: 'folder-7',
        name: 'JLPT N5',
        description: null,
        color: '#22C55E',
        createdAt: 0,
      ),
      totalWords: 10,
      unlearnedCount: 4,
      dueCount: 2,
      lv6Count: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FolderProgressList(
            folders: const [item],
            onOpenFolder: (id) => openedId = id,
            onEditFolder: (value) => edited = value,
            onDeleteFolder: (value) => deleted = value,
          ),
        ),
      ),
    );

    expect(find.text('10 từ • 4 từ chưa học'), findsOneWidget);
    expect(find.text('60% đã học'), findsOneWidget);
    expect(find.text('2 cần ôn'), findsOneWidget);

    await tester.tap(find.byTooltip('Tùy chọn bộ từ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa bộ từ'));
    await tester.pumpAndSettle();
    expect(edited, item);

    await tester.tap(find.byTooltip('Tùy chọn bộ từ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa bộ từ'));
    await tester.pumpAndSettle();
    expect(deleted, item);

    await tester.tap(find.text('JLPT N5'));
    await tester.pump();
    expect(openedId, 'folder-7');
    expect(tester.takeException(), isNull);
  });

  testWidgets('reorder mode exposes drag handles and reports the new position',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int? oldIndex;
    int? newIndex;
    const items = [
      FolderWithCount(
        folder: Folder(
          id: 'folder-1',
          name: 'JLPT N5',
          color: '#22C55E',
          createdAt: 0,
          sortOrder: 0,
        ),
        totalWords: 10,
        unlearnedCount: 4,
        dueCount: 2,
        lv6Count: 1,
      ),
      FolderWithCount(
        folder: Folder(
          id: 'folder-2',
          name: 'JLPT N4',
          color: '#0EA5E9',
          createdAt: 1,
          sortOrder: 1,
        ),
        totalWords: 8,
        unlearnedCount: 3,
        dueCount: 0,
        lv6Count: 2,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FolderProgressList(
            folders: items,
            reorderEnabled: true,
            onReorder: (from, to) {
              oldIndex = from;
              newIndex = to;
            },
            onOpenFolder: (_) {},
            onEditFolder: (_) {},
            onDeleteFolder: (_) {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Kéo để sắp xếp'), findsNWidgets(2));
    expect(find.byTooltip('Tùy chọn bộ từ'), findsNothing);

    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorderItem!(0, 1);

    expect(oldIndex, 0);
    expect(newIndex, 1);
  });

  testWidgets('library only persists the draft order after Save is tapped',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _FakeFolderStore(List.of(_reorderItems));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cloudStoreProvider.overrideWithValue(store)],
        child: const MaterialApp(home: FolderListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Sắp xếp'));
    await tester.pump();
    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    reorderable.onReorderItem!(0, 1);
    await tester.pump();

    expect(store.reorderCallCount, 0);
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(store.reorderCallCount, 1);
    expect(store.lastOrderedIds, ['folder-2', 'folder-1']);
    expect(find.text('Đã lưu thứ tự bộ từ.'), findsOneWidget);
  });
}

const _reorderItems = [
  FolderWithCount(
    folder: Folder(
      id: 'folder-1',
      name: 'JLPT N5',
      color: '#22C55E',
      createdAt: 0,
      sortOrder: 0,
    ),
    totalWords: 10,
    unlearnedCount: 4,
    dueCount: 2,
    lv6Count: 1,
  ),
  FolderWithCount(
    folder: Folder(
      id: 'folder-2',
      name: 'JLPT N4',
      color: '#0EA5E9',
      createdAt: 1,
      sortOrder: 1,
    ),
    totalWords: 8,
    unlearnedCount: 3,
    dueCount: 0,
    lv6Count: 2,
  ),
];

class _FakeFolderStore extends CloudStore {
  _FakeFolderStore(this.items)
      : super(
          SupabaseClient(
            'https://example.supabase.co',
            'test-key',
            authOptions: const AuthClientOptions(autoRefreshToken: false),
          ),
        );

  List<FolderWithCount> items;
  int reorderCallCount = 0;
  List<String>? lastOrderedIds;

  @override
  Future<List<FolderWithCount>> getFolderSummaries() async => List.of(items);

  @override
  Future<void> reorderFolders(List<String> orderedIds) async {
    reorderCallCount++;
    lastOrderedIds = List.of(orderedIds);
    final byId = {for (final item in items) item.folder.id: item};
    items = [for (final id in orderedIds) byId[id]!];
  }
}
