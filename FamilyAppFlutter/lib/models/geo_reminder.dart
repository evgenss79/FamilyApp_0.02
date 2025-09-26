import '../utils/parsing.dart';

/// Represents a persisted geo-reminder tied to a family entity such as a task
/// or calendar event. Stored inside the encrypted Hive cache so background
/// workers can evaluate proximity without hitting Firestore.
class GeoReminder {
  const GeoReminder({
    required this.id,
    required this.familyId,
    required this.sourceId,
    required this.sourceType,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.locationLabel,
    this.payload,
    this.lastTriggeredAt,
  });

  final String id;
  final String familyId;
  final String sourceId;
  final String sourceType;
  final String title;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final String? locationLabel;
  final String? payload;
  final DateTime? lastTriggeredAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'familyId': familyId,
        'sourceId': sourceId,
        'sourceType': sourceType,
        'title': title,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'locationLabel': locationLabel,
        'payload': payload,
        'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
      };

  factory GeoReminder.fromMap(Map<String, dynamic> map) {
    return GeoReminder(
      id: (map['id'] ?? '').toString(),
      familyId: (map['familyId'] ?? '').toString(),
      sourceId: (map['sourceId'] ?? '').toString(),
      sourceType: (map['sourceType'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble() ?? 0,
      locationLabel: map['locationLabel'] as String?,
      payload: map['payload'] as String?,
      lastTriggeredAt: parseNullableDateTime(map['lastTriggeredAt']),
    );
  }

  GeoReminder copyWith({
    String? id,
    String? familyId,
    String? sourceId,
    String? sourceType,
    String? title,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    String? locationLabel,
    String? payload,
    DateTime? lastTriggeredAt,
  }) {
    return GeoReminder(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      sourceId: sourceId ?? this.sourceId,
      sourceType: sourceType ?? this.sourceType,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      locationLabel: locationLabel ?? this.locationLabel,
      payload: payload ?? this.payload,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
    );
  }
}
