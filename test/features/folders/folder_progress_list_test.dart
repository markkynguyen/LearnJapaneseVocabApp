import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jvocab/core/database/app_database.dart';
import 'package:jvocab/features/folders/presentation/widgets/folder_progress_list.dart';

void main() {
  testWidgets('library progress card opens folder and exposes edit/delete menu',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    int? openedId;
    FolderWithCount? edited;
    FolderWithCount? deleted;
    const item = FolderWithCount(
      folder: Folder(
        id: 7,
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

    expect(find.text('10 từ • 4 từ chưa học • 2 từ cần ôn'), findsOneWidget);
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
    expect(openedId, 7);
    expect(tester.takeException(), isNull);
  });
}
