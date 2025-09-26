import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/event.dart';
import '../models/family_member.dart';
import '../models/task.dart';
import '../repositories/events_repository.dart';
import '../repositories/members_repository.dart';
import '../repositories/tasks_repository.dart';
import '../services/geo_reminders_service.dart';
import '../services/notifications_service.dart';
import '../services/sync_service.dart';

/// Holds shared state for family members, tasks and events. The provider reads
/// from the encrypted Hive caches maintained by the repositories and requests
/// the [SyncService] to push pending changes to Firestore when necessary.
class FamilyData extends ChangeNotifier {
  FamilyData({
    required this.familyId,
    required MembersRepository membersRepository,
    required TasksRepository tasksRepository,
    required EventsRepository eventsRepository,
    required SyncService syncService,
    required NotificationsService notificationsService,
    required GeoRemindersService geoRemindersService,
  })  : _membersRepository = membersRepository,
        _tasksRepository = tasksRepository,
        _eventsRepository = eventsRepository,
        _syncService = syncService,
        _notifications = notificationsService,
        _geoReminders = geoRemindersService;

  final String familyId;

  final MembersRepository _membersRepository;
  final TasksRepository _tasksRepository;
  final EventsRepository _eventsRepository;
  final SyncService _syncService;
  final NotificationsService _notifications;
  final GeoRemindersService _geoReminders;

  final List<FamilyMember> members = <FamilyMember>[];
  final List<Task> tasks = <Task>[];
  final List<Event> events = <Event>[];

  bool _loaded = false;
  bool _isLoading = false;

  StreamSubscription<List<FamilyMember>>? _membersSubscription;
  StreamSubscription<List<Task>>? _tasksSubscription;
  StreamSubscription<List<Event>>? _eventsSubscription;

  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_loaded || _isLoading) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      members
        ..clear()
        ..addAll(await _membersRepository.loadLocal(familyId));
      tasks
        ..clear()
        ..addAll(await _tasksRepository.loadLocal(familyId));
      _sortTasks();
      events
        ..clear()
        ..addAll(await _eventsRepository.loadLocal(familyId));

      _membersSubscription = _membersRepository.watchLocal(familyId).listen(
        (List<FamilyMember> updatedMembers) {
          members
            ..clear()
            ..addAll(updatedMembers);
          notifyListeners();
        },
      );
      _tasksSubscription = _tasksRepository.watchLocal(familyId).listen(
        (List<Task> updatedTasks) {
          tasks
            ..clear()
            ..addAll(updatedTasks);
          _sortTasks();
          notifyListeners();
          unawaited(_rescheduleTaskReminders());
        },
      );
      _eventsSubscription = _eventsRepository.watchLocal(familyId).listen(
        (List<Event> updatedEvents) {
          events
            ..clear()
            ..addAll(updatedEvents);
          notifyListeners();
          unawaited(_rescheduleEventReminders());
        },
      );
      _loaded = true;
      await _syncService.flush();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  FamilyMember? memberById(String? memberId) {
    if (memberId == null) {
      return null;
    }
    try {
      return members.firstWhere((FamilyMember member) => member.id == memberId);
    } catch (_) {
      return null;
    }
  }

  Future<void> addMember(FamilyMember member) async {
    await _membersRepository.saveLocal(familyId, member);
    await _syncService.flush();
  }

  Future<void> updateMember(FamilyMember member) async {
    await _membersRepository.saveLocal(familyId, member);
    await _syncService.flush();
  }

  Future<void> updateMemberDocuments(
    String memberId, {
    String? summary,
    List<Map<String, String>>? documentsList,
  }) async {
    final int index = members.indexWhere((FamilyMember m) => m.id == memberId);
    if (index == -1) {
      return;
    }
    final FamilyMember updated = members[index].copyWith(
      documents: summary,
      documentsList: documentsList,
    );
    await _membersRepository.saveLocal(familyId, updated);
    await _syncService.flush();
  }

  Future<void> updateMemberNetworks({
    required String memberId,
    List<Map<String, String>>? socialNetworks,
    List<Map<String, String>>? messengers,
    String? socialSummary,
  }) async {
    final int index = members.indexWhere((FamilyMember m) => m.id == memberId);
    if (index == -1) {
      return;
    }
    final FamilyMember updated = members[index].copyWith(
      socialNetworks: socialNetworks,
      messengers: messengers,
      socialMedia: socialSummary,
    );
    await _membersRepository.saveLocal(familyId, updated);
    await _syncService.flush();
  }

  Future<void> updateMemberHobbies(String memberId, String? hobbies) async {
    final int index = members.indexWhere((FamilyMember m) => m.id == memberId);
    if (index == -1) {
      return;
    }
    final FamilyMember updated = members[index].copyWith(hobbies: hobbies);
    await _membersRepository.saveLocal(familyId, updated);
    await _syncService.flush();
  }

  Future<void> removeMember(FamilyMember member) async {
    await _membersRepository.markDeleted(familyId, member.id);
    await _syncService.flush();
  }

  Future<void> removeMemberById(String id) async {
    await _membersRepository.markDeleted(familyId, id);
    await _syncService.flush();
  }

  Task? taskById(String id) {
    try {
      return tasks.firstWhere((Task task) => task.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addTask(Task task) async {
    await _tasksRepository.saveLocal(familyId, task);
    await _syncService.flush();
    await _rescheduleTaskReminders();
  }

  Future<void> updateTask(Task task) async {
    await _tasksRepository.saveLocal(familyId, task);
    await _syncService.flush();
    await _rescheduleTaskReminders();
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    final int index = tasks.indexWhere((Task task) => task.id == taskId);
    if (index == -1) {
      return;
    }
    final Task updated = tasks[index].copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );
    await _tasksRepository.saveLocal(familyId, updated);
    await _syncService.flush();
    await _rescheduleTaskReminders();
  }

  Future<void> assignTask(String id, String? assigneeId) async {
    final int index = tasks.indexWhere((Task task) => task.id == id);
    if (index == -1) {
      return;
    }
    final Task updated = tasks[index].copyWith(assigneeId: assigneeId);
    await _tasksRepository.saveLocal(familyId, updated);
    await _syncService.flush();
    await _rescheduleTaskReminders();
  }

  Future<void> removeTask(String id) async {
    await _tasksRepository.markDeleted(familyId, id);
    await _syncService.flush();
    await _notifications.cancelNotificationForKey(_taskNotificationKey(id));
    await _geoReminders.removeTaskReminder(familyId, id);
  }

  Event? eventById(String id) {
    try {
      return events.firstWhere((Event event) => event.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addEvent(Event event) async {
    await _eventsRepository.saveLocal(familyId, event);
    await _syncService.flush();
    await _rescheduleEventReminders();
  }

  Future<void> updateEvent(Event event) async {
    await _eventsRepository.saveLocal(familyId, event);
    await _syncService.flush();
    await _rescheduleEventReminders();
  }

  Future<void> removeEvent(String id) async {
    await _eventsRepository.markDeleted(familyId, id);
    await _syncService.flush();
    await _notifications.cancelNotificationForKey(_eventNotificationKey(id));
    await _geoReminders.removeEventReminder(familyId, id);
  }

  @override
  void dispose() {
    _membersSubscription?.cancel();
    _tasksSubscription?.cancel();
    _eventsSubscription?.cancel();
    super.dispose();
  }

  void _sortTasks() {
    tasks.sort((Task a, Task b) {
      final DateTime aDue = a.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDue = b.dueDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDue.compareTo(bDue);
    });
  }

  Future<void> _rescheduleTaskReminders() async {
    await _geoReminders.syncTaskReminders(familyId, tasks);
    for (final Task task in tasks) {
      final String key = _taskNotificationKey(task.id);
      if (task.reminderEnabled && task.dueDate != null) {
        final DateTime scheduled = task.dueDate!;
        await _notifications.scheduleDeadlineNotification(
          key: key,
          scheduledFor: scheduled,
          title: task.title,
          body: task.description ?? task.title,
        );
      } else {
        await _notifications.cancelNotificationForKey(key);
      }
    }
  }

  Future<void> _rescheduleEventReminders() async {
    await _geoReminders.syncEventReminders(familyId, events);
    for (final Event event in events) {
      final String key = _eventNotificationKey(event.id);
      if (event.reminderEnabled) {
        final Duration offset = Duration(
          minutes: event.reminderMinutesBefore ?? 15,
        );
        final DateTime scheduled = event.startDateTime.subtract(offset);
        await _notifications.scheduleDeadlineNotification(
          key: key,
          scheduledFor: scheduled,
          title: event.title,
          body: event.description ?? event.title,
        );
      } else {
        await _notifications.cancelNotificationForKey(key);
      }
    }
  }

  String _taskNotificationKey(String id) => 'task:$familyId:$id';

  String _eventNotificationKey(String id) => 'event:$familyId:$id';
}
