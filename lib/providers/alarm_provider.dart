import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/alarm_model.dart';
import 'package:uuid/uuid.dart';

final alarmProvider = StateNotifierProvider<AlarmNotifier, List<AlarmModel>>((ref) {
  return AlarmNotifier();
});

class AlarmNotifier extends StateNotifier<List<AlarmModel>> {
  AlarmNotifier() : super([]) {
    _loadAlarms();
  }

  final _boxName = 'alarmsBox';

  void _loadAlarms() {
    final box = Hive.box(_boxName);
    final List<AlarmModel> loadedAlarms = [];
    for (var key in box.keys) {
      final map = box.get(key) as Map<dynamic, dynamic>;
      loadedAlarms.add(AlarmModel.fromMap(map));
    }
    state = loadedAlarms;
  }

  Future<void> addAlarm(String name, double lat, double lng, double radius, {String? contactNumber}) async {
    final newAlarm = AlarmModel(
      id: const Uuid().v4(),
      name: name,
      latitude: lat,
      longitude: lng,
      radiusInMeters: radius,
      isActive: true,
      contactNumber: contactNumber,
    );
    final box = Hive.box(_boxName);
    await box.put(newAlarm.id, newAlarm.toMap());
    state = [...state, newAlarm];
  }

  Future<void> toggleAlarm(String id) async {
    final box = Hive.box(_boxName);
    final alarmIndex = state.indexWhere((a) => a.id == id);
    if (alarmIndex != -1) {
      final alarm = state[alarmIndex];
      final updatedAlarm = AlarmModel(
        id: alarm.id,
        name: alarm.name,
        latitude: alarm.latitude,
        longitude: alarm.longitude,
        radiusInMeters: alarm.radiusInMeters,
        isActive: !alarm.isActive,
        contactNumber: alarm.contactNumber,
      );
      await box.put(id, updatedAlarm.toMap());
      final newState = [...state];
      newState[alarmIndex] = updatedAlarm;
      state = newState;
    }
  }

  Future<void> deleteAlarm(String id) async {
    final box = Hive.box(_boxName);
    await box.delete(id);
    state = state.where((a) => a.id != id).toList();
  }
}
