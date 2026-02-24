import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Rome'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _isInitialized = true;
  }

  // Schedule daily notification at 18:00 (excluding weekends and holidays)
  Future<void> scheduleDailyReminder() async {
    try {
      await _notifications.cancelAll();
    } catch (e) {
      return;
    }

    // Schedule for next 30 days
    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.add(Duration(days: i));

      // Skip weekends
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        continue;
      }

      // Skip Italian holidays (basic list)
      if (_isItalianHoliday(date)) {
        continue;
      }

      final scheduledDate = DateTime(date.year, date.month, date.day, 18, 0);

      if (scheduledDate.isAfter(now)) {
        try {
          await _scheduleNotification(
            id: i,
            title: 'Reminder Consuntivazione',
            body: 'Non dimenticare di consuntivare le ore di oggi!',
            scheduledDate: scheduledDate,
          );
        } catch (e) {
          // Non-blocking: skip notification if platform does not allow alarms.
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'timesheet_reminder',
            'Timesheet Reminders',
            channelDescription: 'Daily reminders for timesheet submission',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          tz.TZDateTime.from(scheduledDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'timesheet_reminder',
              'Timesheet Reminders',
              channelDescription: 'Daily reminders for timesheet submission',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexact,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } else {
        rethrow;
      }
    }
  }

  // Check if date is Italian holiday
  bool _isItalianHoliday(DateTime date) {
    // Basic Italian holidays
    final holidays = [
      DateTime(date.year, 1, 1), // Capodanno
      DateTime(date.year, 1, 6), // Epifania
      DateTime(date.year, 4, 25), // Liberazione
      DateTime(date.year, 5, 1), // Festa del Lavoro
      DateTime(date.year, 6, 2), // Festa della Repubblica
      DateTime(date.year, 8, 15), // Ferragosto
      DateTime(date.year, 11, 1), // Ognissanti
      DateTime(date.year, 12, 8), // Immacolata
      DateTime(date.year, 12, 25), // Natale
      DateTime(date.year, 12, 26), // Santo Stefano
    ];

    return holidays.any(
      (holiday) =>
          holiday.year == date.year &&
          holiday.month == date.month &&
          holiday.day == date.day,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
