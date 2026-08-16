
class AlarmModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusInMeters;
  final bool isActive;
  final String? contactNumber;
  final DateTime? validFrom;
  final DateTime? validTo;

  AlarmModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusInMeters,
    this.isActive = true,
    this.contactNumber,
    this.validFrom,
    this.validTo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radiusInMeters': radiusInMeters,
      'isActive': isActive,
      'contactNumber': contactNumber,
      'validFrom': validFrom?.toIso8601String(),
      'validTo': validTo?.toIso8601String(),
    };
  }

  factory AlarmModel.fromMap(Map<dynamic, dynamic> map) {
    return AlarmModel(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'] is int ? (map['latitude'] as int).toDouble() : map['latitude'],
      longitude: map['longitude'] is int ? (map['longitude'] as int).toDouble() : map['longitude'],
      radiusInMeters: map['radiusInMeters'] is int ? (map['radiusInMeters'] as int).toDouble() : map['radiusInMeters'],
      isActive: map['isActive'] ?? true,
      contactNumber: map['contactNumber'],
      validFrom: map['validFrom'] != null ? DateTime.tryParse(map['validFrom']) : null,
      validTo: map['validTo'] != null ? DateTime.tryParse(map['validTo']) : null,
    );
  }
}
