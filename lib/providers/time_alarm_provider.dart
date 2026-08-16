import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/time_alarm_model.dart';
import '../services/notification_service.dart';
import 'package:uuid/uuid.dart';

final timeAlarmProvider = StateNotifierProvider<TimeAlarmNotifier, List<TimeAlarmModel>>((ref) {
  return TimeAlarmNotifier();
});

class TimeAlarmNotifier extends StateNotifier<List<TimeAlarmModel>> {
  TimeAlarmNotifier() : super([]) {
    _loadAlarms();
  }

  final _boxName = 'timeAlarmsBox';

  void _loadAlarms() {
    final box = Hive.box(_boxName);
    final List<TimeAlarmModel> loadedAlarms = [];
    for (var key in box.keys) {
      final map = box.get(key) as Map<dynamic, dynamic>;
      loadedAlarms.add(TimeAlarmModel.fromMap(map));
    }
    // Sort by scheduled time
    loadedAlarms.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    state = loadedAlarms;
  }

  Future<void> addAlarm(String name, DateTime scheduledDateTime, bool continuousRing) async {
    final newAlarm = TimeAlarmModel(
      id: const Uuid().v4(),
      name: name,
      scheduledDateTime: scheduledDateTime,
      isActive: true,
      continuousRing: continuousRing,
    );
    final box = Hive.box(_boxName);
    await box.put(newAlarm.id, newAlarm.toMap());
    
    // Schedule the notification
    await NotificationService.scheduleTimeAlarm(newAlarm);
    
    state = [...state, newAlarm]..sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
  }

  Future<void> toggleAlarm(String id) async {
    final box = Hive.box(_boxName);
    final alarmIndex = state.indexWhere((a) => a.id == id);
    if (alarmIndex != -1) {
      final alarm = state[alarmIndex];
      final updatedAlarm = TimeAlarmModel(
        id: alarm.id,
        name: alarm.name,
        scheduledDateTime: alarm.scheduledDateTime,
        isActive: !alarm.isActive,
        continuousRing: alarm.continuousRing,
      );
      await box.put(id, updatedAlarm.toMap());
      
      if (updatedAlarm.isActive) {
        if (updatedAlarm.scheduledDateTime.isAfter(DateTime.now())) {
          await NotificationService.scheduleTimeAlarm(updatedAlarm);
        }
      } else {
        await NotificationService.cancelAlarm(updatedAlarm.id);
      }
      
      final newState = [...state];
      newState[alarmIndex] = updatedAlarm;
      state = newState;
    }
  }

  Future<void> deleteAlarm(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
    await NotificationService.cancelAlarm(id);
    state = state.where((a) => a.id != id).toList();
  }
}
