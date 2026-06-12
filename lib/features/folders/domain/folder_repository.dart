import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';

class FolderRepository {
  const FolderRepository(this._folderDao);

  final FolderDao _folderDao;

  Stream<List<FolderWithCount>> watchFolders() {
    return _folderDao.watchFoldersWithCount();
  }

  Future<Folder?> getFolderById(int id) {
    return _folderDao.getFolderById(id);
  }

  Future<int> createFolder({
    required String name,
    required String color,
    String? description,
  }) {
    return _folderDao.insertFolder(
      FoldersCompanion.insert(
        name: name.trim(),
        description: Value(_emptyToNull(description)),
        color: Value(color),
      ),
    );
  }

  Future<bool> updateFolder({
    required int id,
    required String name,
    required String color,
    required int createdAt,
    String? description,
  }) {
    return _folderDao.updateFolder(
      FoldersCompanion(
        id: Value(id),
        name: Value(name.trim()),
        description: Value(_emptyToNull(description)),
        color: Value(color),
        createdAt: Value(createdAt),
      ),
    );
  }

  Future<int> deleteFolder(int id) {
    return _folderDao.deleteFolder(id);
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
