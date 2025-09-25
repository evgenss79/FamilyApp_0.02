import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../models/family_member.dart';
import '../security/encrypted_firestore_service.dart';
import '../storage/local_store.dart';

class AuthUserContext {
  AuthUserContext({required this.familyId, required this.member});

  final String familyId;
  final FamilyMember member;
}

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
    EncryptedFirestoreService? encryption,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _encryption = encryption ?? const EncryptedFirestoreService();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
  final EncryptedFirestoreService _encryption;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConfig.usersCollection);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Google sign-in aborted by user',
      );
    }

    final GoogleSignInAuthentication auth = await account.authentication;
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait<void>(<Future<void>>[
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<AuthUserContext?> loadUserContext(User user) async {
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _users.doc(user.uid).get();
    if (!userSnapshot.exists) {
      return null;
    }
    final Map<String, dynamic>? data = userSnapshot.data();
    if (data == null) {
      return null;
    }
    final String? familyId = data['familyId'] as String?;
    final String? memberId = data['memberId'] as String?;
    if (familyId == null || memberId == null) {
      return null;
    }

    final DocumentReference<Map<String, dynamic>> memberRef = _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(memberId);
    final DocumentSnapshot<Map<String, dynamic>> memberSnapshot =
        await memberRef.get();
    if (!memberSnapshot.exists) {
      return null;
    }

    final Map<String, dynamic> decrypted =
        await _encryption.decode(memberSnapshot.data());
    if (decrypted.isEmpty) {
      return null;
    }
    decrypted['id'] = memberId;
    decrypted['familyId'] ??= familyId;
    decrypted['userId'] ??= user.uid;
    decrypted['email'] ??= user.email;
    final FamilyMember member = FamilyMember.fromMap(decrypted);
    return AuthUserContext(familyId: familyId, member: member);
  }

  Future<AuthUserContext> createFamilyAndProfile({
    required User user,
    required String displayName,
    required String familyName,
    String? relationship,
  }) async {
    final String familyId = _firestore.collection('families').doc().id;
    final DocumentReference<Map<String, dynamic>> familyRef =
        _firestore.collection('families').doc(familyId);
    final DocumentReference<Map<String, dynamic>> memberRef = familyRef
        .collection('members')
        .doc();
    final String memberId = memberRef.id;

    final DateTime now = DateTime.now().toUtc();
    // ANDROID-ONLY FIX: reuse the FCM token captured during the Android boot.
    final String? token = LocalStore.getFcmToken();

    final Map<String, dynamic> memberMap = <String, dynamic>{
      'id': memberId,
      'userId': user.uid,
      'familyId': familyId,
      'name': displayName,
      'relationship': relationship ?? 'Owner',
      'email': user.email,
      'fcmTokens': token == null ? <String>[] : <String>[token],
      'isAdmin': true,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    await familyRef.set(<String, dynamic>{
      'name': familyName,
      'ownerId': user.uid,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    await _users.doc(user.uid).set(<String, dynamic>{
      'familyId': familyId,
      'memberId': memberId,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'displayName': displayName,
      'email': user.email,
    }, SetOptions(merge: true));

    // SECURITY: write the initial member document through the AES-GCM channel.
    await _encryption.setEncrypted(ref: memberRef, data: memberMap);

    await user.updateDisplayName(displayName);

    final FamilyMember member = FamilyMember.fromMap(memberMap);
    return AuthUserContext(familyId: familyId, member: member);
  }

  Future<AuthUserContext?> refreshContext(User user) {
    return loadUserContext(user);
  }

  Future<void> updateDisplayName(String name) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return;
    }
    await user.updateDisplayName(name);
    await _users.doc(user.uid).set(<String, dynamic>{
      'displayName': name,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    }, SetOptions(merge: true));
  }
}
