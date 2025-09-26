import '../utils/parsing.dart';

/// Calendar event shared between family members.
class Event {
  static const Object _sentinel = Object();

  Event({
    required this.id,
    required this.title,
    required this.startDateTime,
    required this.endDateTime,
    this.description,
    List<String>? participantIds,
    this.createdAt,
    this.updatedAt,
    this.locationLabel,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.reminderEnabled = false,
    this.reminderMinutesBefore,
  }) : participantIds = List.unmodifiable(participantIds ?? <String>[]);

  final String id;
  final String title;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String? description;
  final List<String> participantIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? locationLabel;
  final double? latitude;
  final double? longitude;
  final double? radiusMeters;
  final bool reminderEnabled;
  final int? reminderMinutesBefore;

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      startDateTime: parseDateTimeOrNow(map['startDateTime']),
      endDateTime: parseDateTimeOrNow(map['endDateTime']),
      description: map['description'] as String?,
      participantIds: parseStringList(map['participantIds']),
      createdAt: parseNullableDateTime(map['createdAt']),
      updatedAt: parseNullableDateTime(map['updatedAt']),
      locationLabel: map['locationLabel'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      radiusMeters: (map['radiusMeters'] as num?)?.toDouble(),
      reminderEnabled: map['reminderEnabled'] == true,
      reminderMinutesBefore: (map['reminderMinutesBefore'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'title': title,
        'startDateTime': startDateTime.toIso8601String(),
        'endDateTime': endDateTime.toIso8601String(),
        'description': description,
        'participantIds': participantIds,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'locationLabel': locationLabel,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'reminderEnabled': reminderEnabled,
        'reminderMinutesBefore': reminderMinutesBefore,
      };

  Event copyWith({
    Object? title = _sentinel,
    Object? startDateTime = _sentinel,
    Object? endDateTime = _sentinel,
    Object? description = _sentinel,
    List<String>? participantIds,
    Object? createdAt = _sentinel,
    Object? updatedAt = _sentinel,
    Object? locationLabel = _sentinel,
    Object? latitude = _sentinel,
    Object? longitude = _sentinel,
    Object? radiusMeters = _sentinel,
    Object? reminderEnabled = _sentinel,
    Object? reminderMinutesBefore = _sentinel,
  }) {
    return Event(

      id: id,
      title: title == _sentinel ? this.title : title as String,
      startDateTime: startDateTime == _sentinel
          ? this.startDateTime
          : startDateTime as DateTime,
      endDateTime:
          endDateTime == _sentinel ? this.endDateTime : endDateTime as DateTime,
      description: description == _sentinel
          ? this.description
          : description as String?,
      participantIds: participantIds == null
          ? this.participantIds
          : List.unmodifiable(participantIds),
      createdAt:
          createdAt == _sentinel ? this.createdAt : createdAt as DateTime?,
      updatedAt:
          updatedAt == _sentinel ? this.updatedAt : updatedAt as DateTime?,
      locationLabel: locationLabel == _sentinel
          ? this.locationLabel
          : locationLabel as String?,
      latitude:
          latitude == _sentinel ? this.latitude : latitude as double?,
      longitude:
          longitude == _sentinel ? this.longitude : longitude as double?,
      radiusMeters: radiusMeters == _sentinel
          ? this.radiusMeters
          : radiusMeters as double?,
      reminderEnabled: reminderEnabled == _sentinel
          ? this.reminderEnabled
          : reminderEnabled as bool,
      reminderMinutesBefore: reminderMinutesBefore == _sentinel
          ? this.reminderMinutesBefore
          : reminderMinutesBefore as int?,
    );
  }
}
