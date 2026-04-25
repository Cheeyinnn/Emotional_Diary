import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 1001;

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kuala_Lumpur'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.requestExactAlarmsPermission();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_mood_reminder',
      'Daily Mood Reminder',
      description: 'Reminder to log your daily mood',
      importance: Importance.high,
    );

    await androidPlugin?.createNotificationChannel(channel);
  }

  static Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    await cancelDailyReminder();

    final scheduledTime = _nextInstance(hour, minute);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Time to check in 💚',
      'How are you feeling today?',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_mood_reminder',
          'Daily Mood Reminder',
          channelDescription: 'Reminder to log your daily mood',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_dailyReminderId);
  }

  static Future<void> showTestNotification() async {
    await _plugin.show(
      999,
      'Test notification',
      'Notification service is working.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_mood_reminder',
          'Daily Mood Reminder',
          channelDescription: 'Reminder to log your daily mood',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
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

    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}