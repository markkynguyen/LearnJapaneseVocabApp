import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

part 'notification_service.g.dart';

class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int dailyReviewReminderId = 1001;
  static const String reviewReminderChannelId = 'review_reminder';
  static const String reviewReminderChannelName = 'Nhac on tu vung';
  static const String reviewReminderChannelDescription =
      'Nhac ban on lai cac tu vung den han moi ngay.';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );

    await _plugin.initialize(settings);

    const channel = AndroidNotificationChannel(
      reviewReminderChannelId,
      reviewReminderChannelName,
      description: reviewReminderChannelDescription,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (kIsWeb) {
      return true;
    }

    final androidResult = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    if (androidResult != null) {
      return androidResult;
    }

    final iosResult = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    if (iosResult != null) {
      return iosResult;
    }

    final macResult = await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return macResult ?? true;
  }

  Future<void> scheduleDailyReviewReminder({
    required int hour,
    required int minute,
    int? dueCount,
  }) async {
    await initialize();

    final body = dueCount == null
        ? 'Den gio on lai tu vung tieng Nhat cua ban.'
        : dueCount > 0
            ? 'Ban co $dueCount tu dang den han on tap.'
            : 'Hom nay hay xem lai mot chut de giu nhip hoc nhe.';

    await _plugin.zonedSchedule(
      dailyReviewReminderId,
      'Den gio on tu vung',
      body,
      _nextDailyTime(hour: hour, minute: minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          reviewReminderChannelId,
          reviewReminderChannelName,
          channelDescription: reviewReminderChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'review_reminder',
    );
  }

  Future<void> cancelDailyReviewReminder() async {
    await initialize();
    await _plugin.cancel(dailyReviewReminderId);
  }

  tz.TZDateTime _nextDailyTime({
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}

@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  return NotificationService();
}
