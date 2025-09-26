import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:workmanager/workmanager.dart';

import '../models/event.dart';
import '../models/geo_reminder.dart';
import '../models/task.dart';
import '../security/secure_key_service.dart';
import '../services/notifications_service.dart';
import '../storage/local_store.dart';

const String geoReminderTaskName = 'familyapp.geo_reminder.evaluate';
const String _geoReminderWorkId = 'familyapp_geo_background';
const String _geoRemindersBox = 'geo_reminders';

/// Coordinates geofencing-style reminders for tasks and events using periodic
/// background location checks. Runs entirely on Android via WorkManager.
class GeoRemindersService {
  GeoRemindersService._();

  static final GeoRemindersService instance = GeoRemindersService._();
  static final GeoRemindersService _backgroundInstance = GeoRemindersService._();

  bool _initialized = false;
  final Map<String, GeoReminder> _reminders = <String, GeoReminder>{};

  /// Initializes WorkManager scheduling and loads the cached reminders.
  Future<void> init(NotificationsService notificationsService) async {
    if (_initialized) {
      await notificationsService.ensureGeoReminderChannel();
      return;
    }
    await notificationsService.ensureGeoReminderChannel();

    // ANDROID-ONLY FIX: configure WorkManager to poll for Android geofence hits.
    await Workmanager().initialize(
      geoReminderCallbackDispatcher,
      isInDebugMode: false,
    );
    await Workmanager().registerPeriodicTask(
      _geoReminderWorkId,
      geoReminderTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: const Duration(minutes: 5),
      existingWorkPolicy: ExistingWorkPolicy.keep,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
    );

    await _ensureLocalStore();
    await _loadStoredReminders();
    _initialized = true;
  }

  Future<void> syncTaskReminders(String familyId, List<Task> tasks) async {
    await _ensureLocalStore();
    final Iterable<Task> withGeo = tasks.where(_hasGeoReminder);
    final Map<String, GeoReminder> desired = <String, GeoReminder>{
      for (final Task task in withGeo)
        _reminderKey('task', familyId, task.id): GeoReminder(
          id: _reminderKey('task', familyId, task.id),
          familyId: familyId,
          sourceId: task.id,
          sourceType: 'task',
          title: task.title,
          latitude: task.latitude!,
          longitude: task.longitude!,
          radiusMeters: task.radiusMeters!,
          locationLabel: task.locationLabel,
          payload: 'task:${task.id}',
        ),
    };
    await _reconcileFamilyReminders(familyId, 'task', desired);
  }

  Future<void> syncEventReminders(String familyId, List<Event> events) async {
    await _ensureLocalStore();
    final Iterable<Event> withGeo = events.where(_eventHasGeoReminder);
    final Map<String, GeoReminder> desired = <String, GeoReminder>{
      for (final Event event in withGeo)
        _reminderKey('event', familyId, event.id): GeoReminder(
          id: _reminderKey('event', familyId, event.id),
          familyId: familyId,
          sourceId: event.id,
          sourceType: 'event',
          title: event.title,
          latitude: event.latitude!,
          longitude: event.longitude!,
          radiusMeters: event.radiusMeters!,
          locationLabel: event.locationLabel,
          payload: 'event:${event.id}',
        ),
    };
    await _reconcileFamilyReminders(familyId, 'event', desired);
  }

  Future<void> removeTaskReminder(String familyId, String taskId) async {
    await _removeReminder(_reminderKey('task', familyId, taskId));
  }

  Future<void> removeEventReminder(String familyId, String eventId) async {
    await _removeReminder(_reminderKey('event', familyId, eventId));
  }

  Future<void> evaluateNow() async {
    await _evaluateReminders();
  }

  Future<void> _reconcileFamilyReminders(
    String familyId,
    String sourceType,
    Map<String, GeoReminder> desired,
  ) async {
    await _ensureLocalStore();
    final Box<Map<String, dynamic>> box =
        await LocalStore.openBox<Map<String, dynamic>>(_geoRemindersBox);

    final Iterable<String> existingKeys = _reminders.entries
        .where((entry) => entry.value.familyId == familyId &&
            entry.value.sourceType == sourceType)
        .map((entry) => entry.key)
        .toList();

    for (final String key in existingKeys) {
      if (!desired.containsKey(key)) {
        _reminders.remove(key);
        await box.delete(key);
      }
    }

    for (final MapEntry<String, GeoReminder> entry in desired.entries) {
      _reminders[entry.key] = entry.value;
      await box.put(entry.key, entry.value.toMap());
    }
  }

  Future<void> _removeReminder(String id) async {
    if (_reminders.remove(id) != null) {
      final Box<Map<String, dynamic>> box =
          await LocalStore.openBox<Map<String, dynamic>>(_geoRemindersBox);
      await box.delete(id);
    }
  }

  Future<void> _loadStoredReminders() async {
    final Box<Map<String, dynamic>> box =
        await LocalStore.openBox<Map<String, dynamic>>(_geoRemindersBox);
    _reminders
      ..clear()
      ..addEntries(box.values.map((Map<String, dynamic> value) {
        final GeoReminder reminder = GeoReminder.fromMap(value);
        return MapEntry<String, GeoReminder>(reminder.id, reminder);
      }));
  }

  Future<void> _ensureLocalStore() async {
    try {
      await SecureKeyService.ensureKey();
      await LocalStore.init();
    } catch (_) {
      // init may already be called; ignore errors when re-running.
    }
  }

  bool _hasGeoReminder(Task task) =>
      task.latitude != null &&
      task.longitude != null &&
      task.radiusMeters != null &&
      task.radiusMeters! > 0;

  bool _eventHasGeoReminder(Event event) =>
      event.latitude != null &&
      event.longitude != null &&
      event.radiusMeters != null &&
      event.radiusMeters! > 0;

  static String _reminderKey(String type, String familyId, String id) =>
      '$type:$familyId:$id';

  Future<bool> _evaluateReminders() async {
    await _ensureLocalStore();
    if (_reminders.isEmpty) {
      await _loadStoredReminders();
    }
    if (_reminders.isEmpty) {
      return true;
    }

    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return true;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return true;
    }

    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final DateTime now = DateTime.now().toUtc();
    final Box<Map<String, dynamic>> box =
        await LocalStore.openBox<Map<String, dynamic>>(_geoRemindersBox);

    for (final GeoReminder reminder in _reminders.values.toList()) {
      final double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        reminder.latitude,
        reminder.longitude,
      );
      if (distance <= reminder.radiusMeters) {
        final DateTime? last = reminder.lastTriggeredAt;
        if (last == null || now.difference(last).inMinutes >= 5) {
          await NotificationsService.showGeoReminderFromBackground(
            title: reminder.title,
            body: reminder.locationLabel ?? reminder.title,
            payload: reminder.payload ?? '',
          );
          final GeoReminder updated = reminder.copyWith(lastTriggeredAt: now);
          _reminders[reminder.id] = updated;
          await box.put(reminder.id, updated.toMap());
        }
      }
    }
    return true;
  }

  @visibleForTesting
  Future<bool> handleBackgroundTask(String task) async {
    if (task == geoReminderTaskName) {
      return _evaluateReminders();
    }
    return true;
  }

  static GeoRemindersService get background => _backgroundInstance;
}

@pragma('vm:entry-point')
void geoReminderCallbackDispatcher() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await GeoRemindersService.background._ensureLocalStore();
    return GeoRemindersService.background.handleBackgroundTask(task);
  });
}
