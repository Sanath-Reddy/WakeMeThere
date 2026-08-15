import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/alarm_model.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'my_foreground',
    'MY FOREGROUND SERVICE',
    description: 'This channel is used for important notifications.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'my_foreground',
      initialNotificationTitle: 'Geo Alarm Service',
      initialNotificationContent: 'Monitoring your location...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox('alarmsBox');

  // Dynamic Polling Loop for Battery Saving
  _runMonitoringLoop(service);
}

Future<void> _runMonitoringLoop(ServiceInstance service) async {
  while (true) {
    int nextDelaySeconds = 10; // Default fast polling

    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        try {
          Position position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
          
          final box = Hive.box('alarmsBox');
          double minDistance = double.infinity;

          for (var key in box.keys) {
            final map = box.get(key) as Map<dynamic, dynamic>;
            final alarm = AlarmModel.fromMap(map);
            
            if (alarm.isActive) {
              final distance = Geolocator.distanceBetween(
                position.latitude, position.longitude,
                alarm.latitude, alarm.longitude,
              );

              // Track closest alarm for battery saving
              if (distance < minDistance) {
                minDistance = distance;
              }
              
              if (distance <= alarm.radiusInMeters) {
                // Trigger Alarm Notification
                final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
                flutterLocalNotificationsPlugin.show(
                  id: alarm.id.hashCode,
                  title: '📍 Destination Reached!',
                  body: 'You have arrived at: ${alarm.name}',
                  notificationDetails: const NotificationDetails(
                    android: AndroidNotificationDetails(
                      'geo_alarm_channel',
                      'Geo Alarms',
                      importance: Importance.max,
                      priority: Priority.high,
                      icon: '@mipmap/ic_launcher',
                      playSound: true,
                      enableVibration: true,
                    ),
                  ),
                );

                // Send SMS if contact number exists
                if (alarm.contactNumber != null && alarm.contactNumber!.isNotEmpty) {
                  final Uri smsUri = Uri(
                    scheme: 'sms',
                    path: alarm.contactNumber,
                    queryParameters: <String, String>{
                      'body': 'I have reached ${alarm.name} safely!',
                    },
                  );
                  if (await canLaunchUrl(smsUri)) {
                    await launchUrl(smsUri);
                  }
                }
                
                // Deactivate the alarm
                final updatedAlarm = AlarmModel(
                  id: alarm.id,
                  name: alarm.name,
                  latitude: alarm.latitude,
                  longitude: alarm.longitude,
                  radiusInMeters: alarm.radiusInMeters,
                  isActive: false,
                  contactNumber: alarm.contactNumber,
                );
                await box.put(key, updatedAlarm.toMap());
              }
            }
          }

          // Battery Saver Dynamic Polling Logic
          if (minDistance != double.infinity) {
            if (minDistance > 50000) {
              nextDelaySeconds = 300; // 50km+ away: 5 minutes
            } else if (minDistance > 10000) {
              nextDelaySeconds = 60; // 10km+ away: 1 minute
            } else if (minDistance > 2000) {
              nextDelaySeconds = 30; // 2km+ away: 30 seconds
            }
          } else {
            // No active alarms
            nextDelaySeconds = 60;
          }

        } catch (e) {
          debugPrint("Location Background Error: $e");
        }
      }
    }

    await Future.delayed(Duration(seconds: nextDelaySeconds));
  }
}
