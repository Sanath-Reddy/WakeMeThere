import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'router.dart';
import 'theme.dart';
import 'services/notification_service.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('alarmsBox');
  await Hive.openBox('timeAlarmsBox');
  
  await NotificationService.initialize();
  await initializeBackgroundService();
  tz.initializeTimeZones();

  runApp(
    const ProviderScope(
      child: GeoAlarmApp(),
    ),
  );
}

class GeoAlarmApp extends StatelessWidget {
  const GeoAlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Geo Alarm',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
