import '../../../core/cloud/cloud_store.dart';
import '../../../core/models/app_models.dart';

class FolderRepository {
  const FolderRepository(this._store);
  final CloudStore _store;

  Future<List<FolderWithCount>> getFolders() => _store.getFolderSummaries();
  Future<Folder?> getFolderById(String id) => _store.getFolder(id);

  Future<String> createFolder({
    required String name,
    required String color,
    String? description,
  }) =>
      _store.createFolder(
        name: name.trim(),
        color: color,
        description: _emptyToNull(description),
      );

  Future<void> updateFolder({
    required String id,
    required String name,
    required String color,
    String? description,
  }) =>
      _store.updateFolder(
        id: id,
        name: name.trim(),
        color: color,
        description: _emptyToNull(description),
      );

  Future<void> deleteFolder(String id) => _store.deleteFolder(id);

  Future<void> reorderFolders(List<String> orderedIds) =>
      _store.reorderFolders(orderedIds);

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
