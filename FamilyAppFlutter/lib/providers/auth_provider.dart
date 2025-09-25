import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/family_member.dart';
import '../services/auth_service.dart';
import '../services/notifications_service.dart';

enum AuthStatus { loading, unauthenticated, needsProfile, authenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthService authService,
    required NotificationsService notificationsService,
  })  : _authService = authService,
        _notificationsService = notificationsService {
    _subscription = _authService.authStateChanges().listen(_handleAuthState);
  }

  final AuthService _authService;
  final NotificationsService _notificationsService;
  StreamSubscription<User?>? _subscription;

  AuthStatus _status = AuthStatus.loading;
  bool _isBusy = false;
  String? _errorMessage;
  String? _familyId;
  FamilyMember? _currentMember;

  AuthStatus get status => _status;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  String? get familyId => _familyId;
  FamilyMember? get currentMember => _currentMember;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _run(() => _authService.signInWithEmail(email: email, password: password));
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String familyName,
    String? relationship,
  }) async {
    await _run(() async {
      final UserCredential credential = await _authService.registerWithEmail(
        email: email,
        password: password,
      );
      final User? user = credential.user ?? _authService.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-null',
          message: 'User not available after registration',
        );
      }
      final AuthUserContext context = await _authService.createFamilyAndProfile(
        user: user,
        displayName: displayName,
        familyName: familyName,
        relationship: relationship,
      );
      await _applyContext(context);
    });
  }

  Future<void> signInWithGoogle() async {
    await _run(_authService.signInWithGoogle);
  }

  Future<void> completeProfile({
    required String displayName,
    required String familyName,
    String? relationship,
  }) async {
    final User? user = _authService.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No authenticated user to complete profile for',
      );
    }
    await _run(() async {
      final AuthUserContext context = await _authService.createFamilyAndProfile(
        user: user,
        displayName: displayName,
        familyName: familyName,
        relationship: relationship,
      );
      await _applyContext(context);
    });
  }

  Future<void> signOut() async {
    await _run(_authService.signOut);
  }

  Future<void> refreshProfile() async {
    final User? user = _authService.currentUser;
    if (user == null) {
      return;
    }
    final AuthUserContext? context = await _authService.refreshContext(user);
    if (context != null) {
      await _applyContext(context, notify: true);
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void updateCurrentMember(FamilyMember member) {
    _currentMember = member;
    notifyListeners();
    final String? name = member.name?.trim();
    if (name != null && name.isNotEmpty) {
      // ANDROID-ONLY FIX: mirror Android profile edits back into Firebase Auth display names.
      unawaited(
        _authService.updateDisplayName(name).catchError((Object error, StackTrace stackTrace) {
          developer.log(
            'Unable to sync display name',
            name: 'AuthProvider',
            error: error,
            stackTrace: stackTrace,
          );
        }),
      );
    }
  }

  Future<void> _run(FutureOr<dynamic> Function() block) async {
    if (_isBusy) return;
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await block();
    } on FirebaseAuthException catch (error) {
      _errorMessage = error.message ?? error.code;
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _handleAuthState(User? user) async {
    if (user == null) {
      await _notificationsService.clearFamilyContext();
      _familyId = null;
      _currentMember = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _status = AuthStatus.loading;
    notifyListeners();
    final AuthUserContext? context = await _authService.loadUserContext(user);
    if (context == null) {
      _status = AuthStatus.needsProfile;
      notifyListeners();
      return;
    }
    await _applyContext(context);
  }

  Future<void> _applyContext(AuthUserContext context, {bool notify = true}) async {
    _familyId = context.familyId;
    _currentMember = context.member;
    _status = AuthStatus.authenticated;
    _errorMessage = null;
    
    await _notificationsService.setActiveFamily(context.familyId);
    if (notify) {
      notifyListeners();
    }
    // ANDROID-ONLY FIX: tie the refreshed Android FCM token to the profile.
    await _notificationsService.syncTokenToMember(
      familyId: context.familyId,
      memberId: context.member.id,
    );
  }
}
