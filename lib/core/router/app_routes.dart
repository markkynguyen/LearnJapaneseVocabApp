abstract final class AppRoutes {
  static const home = '/';
  static const folders = '/folders';
  static const newFolder = '/folders/new';
  static const settings = '/settings';
  static const settingsImport = '/settings/import';
  static const settingsExport = '/settings/export';
  static const review = '/review';
  static const reviewSession = '/review/session';
  static const reviewResult = '/review/result';

  static String editFolder(int id) => '/folders/$id/edit';
  static String folderVocab(int id) => '/folders/$id/vocab';
  static String folderFlashcards(int id) => '/folders/$id/flashcards';
  static String reviewFolder(
    int id, {
    bool favoritesOnly = false,
  }) =>
      favoritesOnly
          ? '/review?folderId=$id&favoritesOnly=1'
          : '/review?folderId=$id';
  static String newVocab(int folderId) => '/folders/$folderId/vocab/new';
  static String editVocab(int id, {required int folderId}) =>
      '/vocab/$id/edit?folderId=$folderId';
}
