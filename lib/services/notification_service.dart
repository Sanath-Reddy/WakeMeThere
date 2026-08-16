import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/time_alarm_model.dart';
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'geo_alarm_channel',
      'Geo Alarms',
      channelDescription: 'Notifications for location based alarms',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  static Future<void> scheduleTimeAlarm(TimeAlarmModel alarm) async {
    final androidSpecifics = AndroidNotificationDetails(
      'time_alarm_channel',
      'Time Alarms',
      channelDescription: 'Notifications for time based alarms',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      additionalFlags: alarm.continuousRing ? Int32List.fromList(<int>[4]) : null, // FLAG_INSISTENT
      timeoutAfter: alarm.continuousRing ? 60000 : null, // 60 seconds max if continuous
    );
    final platformChannelSpecifics = NotificationDetails(android: androidSpecifics);

    await _notificationsPlugin.zonedSchedule(
      alarm.id.hashCode,
      '⏰ Time Alarm: ${alarm.name}',
      'Scheduled alarm is ringing!',
      tz.TZDateTime.from(alarm.scheduledDateTime, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  static Future<void> cancelAlarm(String id) async {
    await _notificationsPlugin.cancel(id.hashCode);
  }
}
