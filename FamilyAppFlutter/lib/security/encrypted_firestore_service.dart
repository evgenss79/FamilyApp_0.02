import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Временная обёртка без реального шифрования.
/// Совместима с вызовами вида:
///   getDecrypted(ref: someDocRef)
///   setEncrypted(ref: someDocRef, data: {...})
class EncryptedFirestoreService {
  final FirebaseFirestore _firestore;

  EncryptedFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getDecrypted({
    required DocumentReference<Map<String, dynamic>> ref,
  }) async {
    final snap = await ref.get();
    if (!snap.exists) return {};
    final data = snap.data();
    if (data == null) return {};
    final enc = data['enc'];
    if (enc is String) {
      try {
        final parsed = json.decode(enc);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (_) {
        // ignore parse errors
      }
    }
    return data;
  }

  Future<void> setEncrypted({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> data,
  }) async {
    final enc = json.encode(data);
    await ref.set({'enc': enc}, SetOptions(merge: true));
  }
}
