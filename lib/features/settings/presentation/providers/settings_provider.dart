import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/notifications/notification_provider.dart';

part 'settings_provider.g.dart';

const String lightThemeModeValue = 'light';
const String darkThemeModeValue = 'dark';

@riverpod
Stream<AppSettings> appSettings(AppSettingsRef ref) {
  return ref.watch(settingsDaoProvider).watchSettings();
}

@riverpod
ThemeMode themeMode(ThemeModeRef ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return settings?.themeMode == darkThemeModeValue
      ? ThemeMode.dark
      : ThemeMode.light;
}

@riverpod
class SettingsController extends _$SettingsController {
  @override
  FutureOr<void> build() {}

  Future<void> updateThemeMode(ThemeMode mode) async {
    state = const AsyncLoading();
    final value =
        mode == ThemeMode.dark ? darkThemeModeValue : lightThemeModeValue;
    state = await AsyncValue.guard(() {
      return ref.read(settingsDaoProvider).updateSettings(
            SettingsCompanion(themeMode: Value(value)),
          );
    });
  }

  Future<bool> updateReminderEnabled(bool enabled) async {
    state = const AsyncLoading();

    if (enabled) {
      final granted = await ref
          .read(notificationControllerProvider.notifier)
          .requestPermission();
      if (!granted) {
        state = const AsyncData(null);
        return false;
      }
    }

    state = await AsyncValue.guard(() async {
      await ref.read(settingsDaoProvider).updateSettings(
            SettingsCompanion(notifyEnabled: Value(enabled)),
          );
      final settings = await ref.read(settingsDaoProvider).getSettings();
      await ref
          .read(notificationControllerProvider.notifier)
          .syncWithSettings(settings);
    });

    return !state.hasError;
  }

  Future<void> updateReminderTime(TimeOfDay time) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(settingsDaoProvider).updateSettings(
            SettingsCompanion(
              notifyHour: Value(time.hour),
              notifyMinute: Value(time.minute),
            ),
          );
      final settings = await ref.read(settingsDaoProvider).getSettings();
      await ref
          .read(notificationControllerProvider.notifier)
          .syncWithSettings(settings);
    });
  }

  Future<void> updateSessionSize(int value) {
    return _updateSettings(
      SettingsCompanion(sessionSize: Value(value.clamp(1, 100))),
    );
  }

  Future<void> updateQuizListenCount(int value) {
    return _updateSettings(
      SettingsCompanion(quizListenCount: Value(value.clamp(0, 10))),
    );
  }

  Future<void> updateQuizWriteCount(int value) {
    return _updateSettings(
      SettingsCompanion(quizWriteCount: Value(value.clamp(0, 10))),
    );
  }

  Future<void> updateQuizChooseWordCount(int value) {
    return _updateSettings(
      SettingsCompanion(quizChooseWordCount: Value(value.clamp(0, 10))),
    );
  }

  Future<void> updateQuizChooseMeaningCount(int value) {
    return _updateSettings(
      SettingsCompanion(quizChooseMeaningCount: Value(value.clamp(0, 10))),
    );
  }

  Future<void> updateQuizRetryLimit(int value) {
    return _updateSettings(
      SettingsCompanion(quizRetryLimit: Value(value.clamp(0, 5))),
    );
  }

  Future<void> updateFlashcardShowKana(bool value) {
    return _updateSettings(SettingsCompanion(flashcardShowKana: Value(value)));
  }

  Future<void> updateFlashcardShowRomaji(bool value) {
    return _updateSettings(
      SettingsCompanion(flashcardShowRomaji: Value(value)),
    );
  }

  Future<void> updateSrsInterval(int level, double days) {
    final normalizedDays = days.clamp(1 / 24, 365).toDouble();
    final companion = switch (level) {
      1 => SettingsCompanion(
          srsLevel1IntervalDays: Value(normalizedDays),
        ),
      2 => SettingsCompanion(
          srsLevel2IntervalDays: Value(normalizedDays),
        ),
      3 => SettingsCompanion(
          srsLevel3IntervalDays: Value(normalizedDays),
        ),
      4 => SettingsCompanion(
          srsLevel4IntervalDays: Value(normalizedDays),
        ),
      5 => SettingsCompanion(
          srsLevel5IntervalDays: Value(normalizedDays),
        ),
      6 => SettingsCompanion(
          srsLevel6IntervalDays: Value(normalizedDays),
        ),
      _ => const SettingsCompanion(),
    };
    return _updateSettings(companion);
  }

  Future<void> _updateSettings(SettingsCompanion companion) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(settingsDaoProvider).updateSettings(companion);
    });
  }
}
