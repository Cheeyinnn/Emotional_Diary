import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();

    // Malaysia timezone
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await _plugin.cancel(1001);

    await _plugin.zonedSchedule(
      1001,
      'Time to check in 💚',
      'How are you feeling today?',
      _nextInstance(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_mood_reminder',
          'Daily Mood Reminder',
          channelDescription: 'Reminder to log your daily mood',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(1001);
  }

  static tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}