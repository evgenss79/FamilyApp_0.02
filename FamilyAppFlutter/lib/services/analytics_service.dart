import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

import '../models/task.dart';

/// Centralizes Firebase Analytics calls for the Android-only FamilyApp build.
class AnalyticsService {
  AnalyticsService._();

  /// Singleton instance shared across the whole app lifecycle.
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Navigator observer that translates navigation changes into analytics
  /// screen view events.
  late final NavigatorObserver navigatorObserver =
      _AnalyticsNavigatorObserver(this);

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }
    await _analytics.setAnalyticsCollectionEnabled(true);
    _initialized = true;
  }

  Future<void> setUserContext({
    required String userId,
    String? familyId,
    String? email,
  }) async {
    await _analytics.setUserId(id: userId);
    if (familyId != null) {
      await _analytics.setUserProperty(name: 'family_id', value: familyId);
    }
    if (email != null && email.isNotEmpty) {
      await _analytics.setUserProperty(name: 'member_email', value: email);
    }
  }

  Future<void> clearUserContext() async {
    await _analytics.setUserId(id: null);
    await _analytics.setUserProperty(name: 'family_id', value: null);
    await _analytics.setUserProperty(name: 'member_email', value: null);
  }

  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  Future<void> logMessageSent({
    required String familyId,
    required String chatId,
    required String messageId,
    required String senderId,
    required String type,
  }) async {
    await _analytics.logEvent(
      name: 'chat_message_sent',
      parameters: <String, Object?>{
        'family_id': familyId,
        'chat_id': chatId,
        'message_id': messageId,
        'sender_id': senderId,
        'message_type': type,
      },
    );
  }

  Future<void> logTaskCreated({
    required String familyId,
    required Task task,
  }) async {
    await _analytics.logEvent(
      name: 'task_created',
      parameters: <String, Object?>{
        'family_id': familyId,
        'task_id': task.id,
        'status': task.status.name,
        'has_due_date': task.dueDate != null,
        'has_geo': task.latitude != null && task.longitude != null,
      },
    );
  }
}

class _AnalyticsNavigatorObserver extends NavigatorObserver {
  _AnalyticsNavigatorObserver(this._analyticsService);

  final AnalyticsService _analyticsService;

  void _log(Route<dynamic>? route) {
    if (route is! PageRoute) {
      return;
    }
    final String screenName =
        route.settings.name ?? route.runtimeType.toString();
    unawaited(
      _analyticsService.logScreenView(
        screenName,
        screenClass: route.runtimeType.toString(),
      ),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _log(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _log(previousRoute);
  }

  @override
  void didReplace({
    Route<dynamic>? newRoute,
    Route<dynamic>? oldRoute,
  }) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _log(newRoute);
  }
}
