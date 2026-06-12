import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/excel_vocab_models.dart';
import '../../domain/import_export_repository.dart';

part 'import_export_provider.g.dart';

@riverpod
ImportExportRepository importExportRepository(ImportExportRepositoryRef ref) {
  return ImportExportRepository(
    vocabularyDao: ref.watch(vocabularyDaoProvider),
    folderDao: ref.watch(folderDaoProvider),
    srsProgressDao: ref.watch(srsProgressDaoProvider),
  );
}

@riverpod
class ImportExportController extends _$ImportExportController {
  @override
  FutureOr<void> build() {}

  Future<ExcelImportPreview?> pickPreview({required int folderId}) {
    return ref
        .read(importExportRepositoryProvider)
        .pickAndPreview(folderId: folderId);
  }

  Future<ExcelImportPreview?> pickPreviewMultipleFolders() {
    return ref
        .read(importExportRepositoryProvider)
        .pickAndPreviewMultipleFolders();
  }

  Future<ExcelImportResult?> importPreview({
    required int folderId,
    required ExcelImportPreview preview,
    required DuplicateStrategy duplicateStrategy,
  }) async {
    state = const AsyncLoading();
    ExcelImportResult? result;
    state = await AsyncValue.guard(() async {
      result = await ref.read(importExportRepositoryProvider).importRows(
            folderId: folderId,
            preview: preview,
            duplicateStrategy: duplicateStrategy,
          );
    });
    return result;
  }

  Future<ExcelImportResult?> importPreviewMultipleFolders({
    required ExcelImportPreview preview,
    required DuplicateStrategy duplicateStrategy,
  }) async {
    state = const AsyncLoading();
    ExcelImportResult? result;
    state = await AsyncValue.guard(() async {
      result =
          await ref.read(importExportRepositoryProvider).importRowsByFolder(
                preview: preview,
                duplicateStrategy: duplicateStrategy,
              );
    });
    return result;
  }

  Future<String?> exportFolder(int folderId) async {
    state = const AsyncLoading();
    String? path;
    state = await AsyncValue.guard(() async {
      path =
          await ref.read(importExportRepositoryProvider).exportFolder(folderId);
    });
    return path;
  }

  Future<String?> exportAll() async {
    state = const AsyncLoading();
    String? path;
    state = await AsyncValue.guard(() async {
      path = await ref.read(importExportRepositoryProvider).exportAll();
    });
    return path;
  }

  Future<String?> exportTemplate() async {
    state = const AsyncLoading();
    String? path;
    state = await AsyncValue.guard(() async {
      path = await ref.read(importExportRepositoryProvider).exportTemplate();
    });
    return path;
  }
}
