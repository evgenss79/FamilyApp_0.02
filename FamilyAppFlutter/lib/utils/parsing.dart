/// Helpers for converting loosely typed persistence layer values into the
/// strongly typed models used throughout the app.
DateTime? parseNullableDateTime(dynamic value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

DateTime parseDateTimeOrNow(dynamic value) {
  return parseNullableDateTime(value) ?? DateTime.now();
}

List<String> parseStringList(dynamic value) {
  if (value is List) {
    return value.map((dynamic element) => element.toString()).toList();
  }
  return const <String>[];
}

Duration? parseDurationFromMinutes(dynamic value) {
  if (value is int) {
    return Duration(minutes: value);
  }
  if (value is String && value.isNotEmpty) {
    final int? minutes = int.tryParse(value);
    if (minutes != null) {
      return Duration(minutes: minutes);
    }
  }
  return null;
}

List<Map<String, String>>? parseStringMapList(dynamic value) {
  if (value is! List) {
    return null;
  }

  final List<Map<String, String>> result = <Map<String, String>>[];
  for (final Object? entry in value) {
    if (entry is! Map<Object?, Object?>) {
      continue;
    }

    final Map<String, String> converted = <String, String>{};
    entry.forEach((Object? key, Object? val) {
      if (key == null) {
        return;
      }
      converted[key.toString()] = val?.toString() ?? '';
    });

    if (converted.isNotEmpty) {
      result.add(converted);
    }
  }

  return result;
}
