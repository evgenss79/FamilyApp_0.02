import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/task.dart';

/// Service that handles geolocation related features for smart reminders.
///
/// The [GeoService] is responsible for obtaining the current location of the
/// device and checking tasks that have associated coordinates. When the
/// device comes within a certain radius of a task’s location, a callback
/// can be triggered. This is a simplified implementation using the
/// `geolocator` plugin. In a production application you might integrate
/// with a background geofencing API to avoid constant polling.
class GeoService {
  static const double _defaultRadiusMeters = 100;

  StreamSubscription<Position>? _positionSub;

  /// Starts listening to location updates and checks tasks in [tasks] for
  /// proximity matches. When a task is within [_defaultRadiusMeters] of
  /// the current location, [onTaskNearby] is called with that task.
  void startProximityMonitoring(
    List<Task> tasks,
    ValueChanged<Task> onTaskNearby,
  ) async {
    // Ensure location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
    }
    // Cancel previous subscription if any
    await _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((position) {
      for (final task in tasks) {
        if (task.latitude == null || task.longitude == null) continue;
        final distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          task.latitude!,
          task.longitude!,
        );
        if (distance <= _defaultRadiusMeters) {
          onTaskNearby(task);
        }
      }
    });
  }

  /// Stops monitoring location updates.
  Future<void> stopProximityMonitoring() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }
}