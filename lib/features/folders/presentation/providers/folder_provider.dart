import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cloud/cloud_store.dart';
import '../../../../core/models/app_models.dart';
import '../../../home/presentation/providers/home_provider.dart';
import '../../../vocab/presentation/providers/vocab_list_provider.dart';
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

  Future<String?> createFolder({
    required String name,
    required String color,
    String? description,
  }) async {
    state = const AsyncLoading();
    String? folderId;
    state = await AsyncValue.guard(() async {
      folderId = await ref
          .read(folderRepositoryProvider)
          .createFolder(name: name, color: color, description: description);
    });
    if (!state.hasError) ref.invalidate(foldersProvider);
    return folderId;
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

  Future<void> setFolderStudyPaused(Folder folder, bool isPaused) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(folderRepositoryProvider).setFolderStudyPaused(
            id: folder.id,
            isPaused: isPaused,
          ),
    );
    if (!state.hasError) {
      ref
        ..invalidate(foldersProvider)
        ..invalidate(folderByIdProvider(folder.id))
        ..invalidate(totalDueCountProvider)
        ..invalidate(totalLevelStatsProvider)
        ..invalidate(folderDueCountProvider(folder.id))
        ..invalidate(folderUnlearnedCountProvider(folder.id))
        ..invalidate(folderLevelStatsProvider(folder.id));
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
