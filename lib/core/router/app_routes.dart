abstract final class AppRoutes {
  static const home = '/';
  static const auth = '/auth';
  static const authCallback = '/auth-callback';
  static const resetPassword = '/reset-password';
  static const configuration = '/configuration';
  static const folders = '/folders';
  static const newFolder = '/folders/new';
  static const settings = '/settings';
  static const settingsImport = '/settings/import';
  static const settingsExport = '/settings/export';
  static const review = '/review';
  static const reviewSession = '/review/session';
  static const reviewResult = '/review/result';
  static const learningSession = '/learning/session';
  static const learningResult = '/learning/result';

  static String editFolder(String id) => '/folders/$id/edit';
  static String folderVocab(String id) => '/folders/$id/vocab';
  static String folderFlashcards(String id) => '/folders/$id/flashcards';
  static String learningPreview(String folderId) =>
      '/learning/folder/$folderId';
  static String reviewExit(String? folderId) =>
      folderId == null ? home : folderVocab(folderId);
  static String reviewFolder(
    String id, {
    bool favoritesOnly = false,
  }) =>
      favoritesOnly
          ? '/review?folderId=$id&favoritesOnly=1'
          : '/review?folderId=$id';
  static String newVocab(String folderId) => '/folders/$folderId/vocab/new';
  static String editVocab(String id, {required String folderId}) =>
      '/vocab/$id/edit?folderId=$folderId';
}
