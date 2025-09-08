EncryptedFirestoreService
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'secure_key_store.dart';
import 'encryption_utils.dart';

class EncryptedFirestoreService {
  final FirebaseFirestore _fs;
  final SecureKeyStore _keys;
  final EncryptionUtils _enc;

  EncryptedFirestoreService({
    FirebaseFirestore? firestore,
    SecureKeyStore? keyStore,
    EncryptionUtils? encryption,
  })  : _fs = firestore ?? FirebaseFirestore.instance,
        _keys = keyStore ?? SecureKeyStore(),
        _enc = encryption ?? EncryptionUtils();

  static const _memberPiiFields = <String>{
    'name',
    'email',
    'phone',
    'messengers',
    'documentNumber',
    'address',
  };

  Future<void> upsertFamilyMember({
    required String familyId,
    required String memberId,
    required Map<String, dynamic> memberData,
    Set<String> piiFields = _memberPiiFields,
  }) async {
    await _keys.ensureDek();
    final dek = await _keys.getDek();

    final publicMap = <String, dynamic>{};
    final piiSource = <String, dynamic>{};

    memberData.forEach((k, v) {
      if (piiFields.contains(k)) {
        piiSource[k] = v ?? '';
      } else {
        publicMap[k] = v;
      }
    });

    final encryptedPii = <String, dynamic>{};
    for (final entry in piiSource.entries) {
      final e = await _enc.encryptString(
        plaintext: entry.value?.toString() ?? '',
        dek: dek,
        aad: {
          'familyId': familyId,
          'memberId': memberId,
          'field': entry.key,
        },
      );
      encryptedPii[entry.key] = e;
    }

    publicMap['pii'] = encryptedPii;
    publicMap['pii_version'] = 1;

    await _fs
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(memberId)
        .set(publicMap, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getFamilyMember({
    required String familyId,
    required String memberId,
    Set<String> piiFields = _memberPiiFields,
  }) async {
    await _keys.ensureDek();
    final dek = await _keys.getDek();

    final snap = await _fs
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(memberId)
        .get();

    if (!snap.exists) return null;
    final data = Map<String, dynamic>.from(snap.data() ?? {});

    final pii = Map<String, dynamic>.from(data['pii'] ?? {});
    for (final field in piiFields) {
      if (pii[field] is Map) {
        final m = Map<String, dynamic>.from(pii[field] as Map);
        final val = await _enc.decryptString(
          nonceB64: m['nonce'],
          cipherB64: m['cipher'],
          tagB64: m['tag'],
          dek: dek,
          aad: {
            'familyId': familyId,
            'memberId': memberId,
            'field': field,
          },
        );
        data[field] = val;
      }
    }
    data.remove('pii');
    return data;
  }

  Future<void> rotateDekForMembers(String familyId) async {
    final oldDek = await _keys.rotateDek();
    final newDek = await _keys.getDek();

    final q = await _fs
        .collection('families')
        .doc(familyId)
        .collection('members')
        .get();

    for (final doc in q.docs) {
      final data = doc.data();
      final pii = Map<String, dynamic>.from(data['pii'] ?? {});
      final reEncrypted = <String, dynamic>{};

      for (final entry in pii.entries) {
        final m = Map<String, dynamic>.from(entry.value as Map);
        final clear = await EncryptionUtils().decryptString(
          nonceB64: m['nonce'],
          cipherB64: m['cipher'],
          tagB64: m['tag'],
          dek: oldDek,
          aad: {
            'familyId': familyId,
            'memberId': doc.id,
            'field': entry.key,
          },
        );
        final encNew = await EncryptionUtils().encryptString(
          plaintext: clear,
          dek: newDek,
          aad: {
            'familyId': familyId,
            'memberId': doc.id,
            'field': entry.key,
          },
        );
        reEncrypted[entry.key] = encNew;
      }

      await doc.reference.update({'pii': reEncrypted});
    }
  }
}
