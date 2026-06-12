import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/folder_repository.dart';

part 'folder_provider.g.dart';

@riverpod
FolderRepository folderRepository(FolderRepositoryRef ref) {
  return FolderRepository(ref.watch(folderDaoProvider));
}

@riverpod
Stream<List<FolderWithCount>> folders(FoldersRef ref) {
  return ref.watch(folderRepositoryProvider).watchFolders();
}

@riverpod
Future<Folder?> folderById(FolderByIdRef ref, int id) {
  return ref.watch(folderRepositoryProvider).getFolderById(id);
}

@riverpod
class FolderController extends _$FolderController {
  @override
  FutureOr<void> build() {}

  Future<void> createFolder({
    required String name,
    required String color,
    String? description,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        await ref.read(folderRepositoryProvider).createFolder(
              name: name,
              color: color,
              description: description,
            );
      },
    );
    if (!state.hasError) {
      ref.invalidate(foldersProvider);
    }
  }

  Future<void> updateFolder({
    required int id,
    required String name,
    required String color,
    required int createdAt,
    String? description,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(folderRepositoryProvider).updateFolder(
            id: id,
            name: name,
            color: color,
            createdAt: createdAt,
            description: description,
          ),
    );
    if (!state.hasError) {
      ref
        ..invalidate(foldersProvider)
        ..invalidate(folderByIdProvider(id));
    }
  }

  Future<void> deleteFolder(int id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(folderRepositoryProvider).deleteFolder(id),
    );
    if (!state.hasError) {
      ref.invalidate(foldersProvider);
    }
  }
}
