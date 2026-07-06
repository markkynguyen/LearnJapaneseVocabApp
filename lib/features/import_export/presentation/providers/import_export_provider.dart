import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cloud/cloud_store.dart';
import '../../domain/excel_vocab_models.dart';
import '../../domain/import_export_repository.dart';

part 'import_export_provider.g.dart';

@riverpod
ImportExportRepository importExportRepository(ImportExportRepositoryRef ref) {
  return ImportExportRepository(
    store: ref.watch(cloudStoreProvider),
  );
}

@riverpod
class ImportExportController extends _$ImportExportController {
  @override
  FutureOr<void> build() {}

  Future<ExcelImportPreview?> pickPreview({required String folderId}) async {
    state = const AsyncLoading();
    ExcelImportPreview? preview;
    state = await AsyncValue.guard(() async {
      preview = await ref
          .read(importExportRepositoryProvider)
          .pickAndPreview(folderId: folderId);
    });
    return preview;
  }

  Future<ExcelImportPreview?> pickPreviewMultipleFolders() async {
    state = const AsyncLoading();
    ExcelImportPreview? preview;
    state = await AsyncValue.guard(() async {
      preview = await ref
          .read(importExportRepositoryProvider)
          .pickAndPreviewMultipleFolders();
    });
    return preview;
  }

  Future<ExcelImportResult?> importPreview({
    required String folderId,
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

  Future<String?> exportFolder(String folderId) async {
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
