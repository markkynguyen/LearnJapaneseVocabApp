import 'package:flutter/material.dart' show ThemeMode;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/cloud/cloud_store.dart';
import '../../../../core/models/app_models.dart';
import '../../../../core/notifications/notification_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

part 'settings_provider.g.dart';

const lightThemeModeValue = 'light';
const darkThemeModeValue = 'dark';
const quizScriptKanjiValue = 'kanji';
const quizScriptKanaValue = 'kana';

@riverpod
Future<AppSettings> appSettings(AppSettingsRef ref) async {
  final id = await ref.watch(deviceIdProvider.future);
  return ref.watch(cloudStoreProvider).getSettings(id);
}

@riverpod
ThemeMode themeMode(ThemeModeRef ref) =>
    ref.watch(currentSessionProvider) == null
        ? ThemeMode.light
        : ref.watch(appSettingsProvider).valueOrNull?.themeMode ==
                darkThemeModeValue
            ? ThemeMode.dark
            : ThemeMode.light;

class SettingsDraftState {
  const SettingsDraftState({
    this.cloudSettings,
    this.draft,
    this.hasChanges = false,
  });

  final AppSettings? cloudSettings;
  final AppSettings? draft;
  final bool hasChanges;
}

@Riverpod(keepAlive: true)
class SettingsDraftController extends _$SettingsDraftController {
  @override
  SettingsDraftState build() {
    ref.listen(appSettingsProvider, (_, next) {
      next.whenData(syncFromCloud);
    });
    ref.listen(currentSessionProvider, (_, session) {
      if (session == null) {
        state = const SettingsDraftState();
      }
    });

    final initial = ref.read(appSettingsProvider).valueOrNull;
    return SettingsDraftState(cloudSettings: initial, draft: initial);
  }

  void syncFromCloud(AppSettings settings) {
    state = SettingsDraftState(
      cloudSettings: settings,
      draft: state.hasChanges ? state.draft : settings,
      hasChanges: state.hasChanges,
    );
  }

  void update(AppSettings settings) {
    state = SettingsDraftState(
      cloudSettings: state.cloudSettings,
      draft: settings,
      hasChanges: true,
    );
  }

  void markSaved(AppSettings settings) {
    state = SettingsDraftState(
      cloudSettings: settings,
      draft: settings,
    );
  }

  void discard() {
    state = SettingsDraftState(
      cloudSettings: state.cloudSettings,
      draft: state.cloudSettings,
    );
  }
}

@Riverpod(keepAlive: true)
class SettingsController extends _$SettingsController {
  @override
  FutureOr<void> build() {}

  Future<bool> saveSettings(AppSettings draft) async {
    state = const AsyncLoading();
    var permissionDenied = false;
    state = await AsyncValue.guard(() async {
      final current = await ref.read(appSettingsProvider.future);
      if (draft.notifyEnabled && !current.notifyEnabled) {
        final granted = await ref
            .read(notificationControllerProvider.notifier)
            .requestPermission();
        if (!granted) {
          permissionDenied = true;
          return;
        }
      }

      final notificationChanged =
          draft.notifyEnabled != current.notifyEnabled ||
              draft.notifyHour != current.notifyHour ||
              draft.notifyMinute != current.notifyMinute;
      final deviceId = await ref.read(deviceIdProvider.future);
      await ref.read(cloudStoreProvider).saveSettings(deviceId, draft);
      final settings = await _reloadSettings();
      if (notificationChanged) {
        await ref
            .read(notificationControllerProvider.notifier)
            .syncWithSettings(settings);
      }
    });
    return !state.hasError && !permissionDenied;
  }

  Future<void> updateFlashcardShowKana(bool value) =>
      _updateLearning({'flashcard_show_kana': value});
  Future<void> updateFlashcardShowRomaji(bool value) =>
      _updateLearning({'flashcard_show_romaji': value});

  Future<void> _updateLearning(Map<String, dynamic> values) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () async {
        await ref.read(cloudStoreProvider).updateLearningSettings(values);
        await _reloadSettings();
      },
    );
  }

  Future<AppSettings> _reloadSettings() async {
    ref.invalidate(appSettingsProvider);
    return ref.read(appSettingsProvider.future);
  }
}
