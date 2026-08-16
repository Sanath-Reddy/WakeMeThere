class TimeAlarmModel {
  final String id;
  final String name;
  final DateTime scheduledDateTime;
  final bool isActive;
  final bool continuousRing;

  TimeAlarmModel({
    required this.id,
    required this.name,
    required this.scheduledDateTime,
    this.isActive = true,
    this.continuousRing = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'isActive': isActive,
      'continuousRing': continuousRing,
    };
  }

  factory TimeAlarmModel.fromMap(Map<dynamic, dynamic> map) {
    return TimeAlarmModel(
      id: map['id'],
      name: map['name'] ?? 'Alarm',
      scheduledDateTime: DateTime.parse(map['scheduledDateTime']),
      isActive: map['isActive'] ?? true,
      continuousRing: map['continuousRing'] ?? false,
    );
  }
}
