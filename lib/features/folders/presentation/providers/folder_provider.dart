import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cloud/cloud_store.dart';
import '../../../../core/models/app_models.dart';
import '../../domain/folder_repository.dart';

part 'folder_provider.g.dart';

@riverpod
FolderRepository folderRepository(FolderRepositoryRef ref) =>
    FolderRepository(ref.watch(cloudStoreProvider));

@riverpod
Future<List<FolderWithCount>> folders(FoldersRef ref) =>
    ref.watch(folderRepositoryProvider).getFolders();

@riverpod
Future<Folder?> folderById(FolderByIdRef ref, String id) =>
    ref.watch(folderRepositoryProvider).getFolderById(id);

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
      () => ref
          .read(folderRepositoryProvider)
          .createFolder(name: name, color: color, description: description),
    );
    if (!state.hasError) ref.invalidate(foldersProvider);
  }

  Future<void> updateFolder({
    required String id,
    required String name,
    required String color,
    String? description,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(folderRepositoryProvider).updateFolder(
            id: id,
            name: name,
            color: color,
            description: description,
          ),
    );
    if (!state.hasError) {
      ref
        ..invalidate(foldersProvider)
        ..invalidate(folderByIdProvider(id));
    }
  }

  Future<void> deleteFolder(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(folderRepositoryProvider).deleteFolder(id),
    );
    if (!state.hasError) ref.invalidate(foldersProvider);
  }

  Future<void> reorderFolders(List<String> orderedIds) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(folderRepositoryProvider).reorderFolders(orderedIds),
    );
    if (!state.hasError) ref.invalidate(foldersProvider);
  }
}
