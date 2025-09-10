import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

import 'secure_key_store.dart';
import 'encryption_utils.dart';

/// Сервис для чтения и записи защифрованных документов в Firestore.
class EncryptedFirestoreService {
  EncryptedFirestoreService({
    FirebaseFirestore? firestore,
    SecureKeyStore? keyStore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _keyStore = keyStore ?? SecureKeyStore();

  final FirebaseFirestore _firestore;
  final SecureKeyStore _keyStore;

  @visibleForTesting
  Future<String> encrypt(String plain) async {
    final key = await _keyStore.getDek();
    return EncryptionUtils.encryptToBase64(plain, key);
  }

  @visibleForTesting
  Future<String> decrypt(String cipher) async {
    final key = await _keyStore.getDek();
    return EncryptionUtils.decryptFromBase64(cipher, key);
  }

  /// Записывает [data] в документ [ref], шифруя строковые поля.
  Future<void> setEncrypted({
    required DocumentReference<Map<String, dynamic>> ref,
    required Map<String, dynamic> data,
    SetOptions? options,
  }) async {
    final Map<String, dynamic> enc = {};
    for (final e in data.entries) {
      final v = e.value;
      if (v is String) {
        enc[e.key] = await encrypt(v);
      } else if (v is num || v is bool) {
        enc[e.key] = v;
      } else {
        enc[e.key] = jsonEncode(v);
      }
    }
    await ref.set(enc, options);
  }

  /// Читает документ [ref], расшифровывает строковые поля и возвращает map.
  Future<Map<String, dynamic>?> getDecrypted({
    required DocumentReference<Map<String, dynamic>> ref,
  }) async {
    final snap = await ref.get();
    if (!snap.exists) return null;

    final src = snap.data()!;
    final Map<String, dynamic> out = {};
    for (final e in src.entries) {
      final v = e.value;
      if (v is String) {
        try {
          out[e.key] = await decrypt(v);
        } catch (_) {
          out[e.key] = v;
        }
      } else {
        out[e.key] = v;
      }
    }
    return out;
  }

  

    FirebaseFirestore get firestore => _firestore;
  
  Future<void> upsertFamilyMember(String familyId, Map<String, dynamic> member) async {
    final id = (member['id'] ?? '').toString();
    if (id.isEmpty) return;
    await _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(id)
        .set(member, SetOptions(merge: true));
  }
}


