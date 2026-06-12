import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import 'notification_service.dart';

part 'notification_provider.g.dart';

@riverpod
class NotificationController extends _$NotificationController {
  @override
  FutureOr<void> build() {}

  Future<bool> requestPermission() {
    return ref.read(notificationServiceProvider).requestPermission();
  }

  Future<void> syncWithSettings(AppSettings settings) async {
    if (!settings.notifyEnabled) {
      await ref.read(notificationServiceProvider).cancelDailyReviewReminder();
      return;
    }

    final dueCount = await ref.read(srsProgressDaoProvider).getDueCount();
    await ref.read(notificationServiceProvider).scheduleDailyReviewReminder(
          hour: settings.notifyHour,
          minute: settings.notifyMinute,
          dueCount: dueCount,
        );
  }
}
