import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../security/encrypted_firestore_service.dart';
import '../storage/local_store.dart';
import '../utils/parsing.dart';

typedef FromMap<T> = T Function(Map<String, dynamic> map);
typedef ToMap<T> = Map<String, dynamic> Function(T value);

/// Base implementation used by repositories that mirror a family scoped
/// Firestore collection into an encrypted Hive box. Handles conflict
/// resolution, pending write queues and snapshot listeners.
abstract class BaseFirestoreRepository<T> {
  BaseFirestoreRepository({
    required this.collectionName,
    required this.fromMap,
    required this.toMap,
    required this.idSelector,
    this.sorter,
    FirebaseFirestore? firestore,
    EncryptedFirestoreService? encryption,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _encryption = encryption ?? const EncryptedFirestoreService();

  final String collectionName;
  final FromMap<T> fromMap;
  final ToMap<T> toMap;
  final String Function(T value) idSelector;
  final Comparator<T>? sorter;

  final FirebaseFirestore _firestore;
  final EncryptedFirestoreService _encryption;

  CollectionReference<Map<String, dynamic>> collectionRef(String familyId) =>
      _firestore
          .collection('families')
          .doc(familyId)
          .collection(collectionName);

  Future<Box<Map<String, dynamic>>> _dataBox(String familyId) async {
    return LocalStore.openBox<Map<String, dynamic>>(
      '${collectionName}_$familyId',
    );
  }

  Future<Box<String>> _deleteBox(String familyId) async {
    return LocalStore.openBox<String>(
      '${collectionName}_$familyId__deletes',
    );
  }

  Future<List<T>> loadLocal(String familyId) async {
    final Box<Map<String, dynamic>> box = await _dataBox(familyId);
    return _deserialize(box.values);
  }

  Stream<List<T>> watchLocal(String familyId) async* {
    final Box<Map<String, dynamic>> box = await _dataBox(familyId);
    yield _deserialize(box.values);
    yield* box.watch().map((_) => _deserialize(box.values));
  }

  Future<T> saveLocal(String familyId, T value, {bool pending = true}) async {
    final Map<String, dynamic> map = Map<String, dynamic>.from(toMap(value));
    final String id = idSelector(value);
    map['id'] = id;
    final DateTime now = DateTime.now().toUtc();
    map['updatedAt'] ??= now.toIso8601String();
    map['createdAt'] ??= now.toIso8601String();
    map['_pending'] = pending;
    final Box<Map<String, dynamic>> box = await _dataBox(familyId);
    await box.put(id, map);
    return fromMap(map);
  }

  Future<void> markDeleted(String familyId, String id) async {
    final Box<Map<String, dynamic>> box = await _dataBox(familyId);
    await box.delete(id);
    final Box<String> deleteBox = await _deleteBox(familyId);
    await deleteBox.put(id, id);
  }

  Future<void> pullRemote(String familyId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await collectionRef(familyId).get();
    final Box<Map<String, dynamic>> box = await _dataBox(familyId);
    await box.clear();
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      final Map<String, dynamic> data = await _decode(doc);
      data['_pending'] = false;
      await box.put(doc.id, data);
    }
  }

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listenRemote(
    String familyId, {
    void Function(DocumentChange<Map<String, dynamic>> change)? onChange,
  }) {
    return collectionRef(familyId).snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) async {
        for (final DocumentChange<Map<String, dynamic>> change
            in snapshot.docChanges) {
          onChange?.call(change);
          await _applyRemoteChange(familyId, change);
        }
      },
    );
  }

  Future<void> pushPending(String familyId) async {
    final Box<Map<String, dynamic>> box = await _dataBox(familyId);
    final Map<dynamic, Map<String, dynamic>> raw =
        Map<dynamic, Map<String, dynamic>>.from(box.toMap());
    final Iterable<MapEntry<dynamic, Map<String, dynamic>>> pendingEntries =
        raw.entries.where((MapEntry<dynamic, Map<String, dynamic>> entry) {
      final Object? flag = entry.value['_pending'];
      return flag is bool && flag;
    });

    final Box<String> deleteBox = await _deleteBox(familyId);
    final List<String> deletions = deleteBox.values.toList();

    if (pendingEntries.isEmpty && deletions.isEmpty) {
      return;
    }

    final WriteBatch batch = _firestore.batch();

    for (final MapEntry<dynamic, Map<String, dynamic>> entry in pendingEntries) {
      final String id = entry.key.toString();
      final Map<String, dynamic> data = Map<String, dynamic>.from(entry.value)
        ..remove('_pending');
      final Map<String, dynamic> payload =
          await _encryption.encryptPayload(data);
      batch.set(collectionRef(familyId).doc(id), payload, SetOptions(merge: true));
    }

    for (final String id in deletions) {
      batch.delete(collectionRef(familyId).doc(id));
    }

    await batch.commit();

    for (final MapEntry<dynamic, Map<String, dynamic>> entry in pendingEntries) {
      entry.value['_pending'] = false;
      await box.put(entry.key.toString(), entry.value);
    }
    await deleteBox.clear();
  }

  Future<void> _applyRemoteChange(
    String familyId,
    DocumentChange<Map<String, dynamic>> change,
  ) async {
    final String id = change.doc.id;
    if (change.type == DocumentChangeType.removed) {
      final Box<Map<String, dynamic>> box = await _dataBox(familyId);
      await box.delete(id);
      return;
    }

    final Map<String, dynamic> remote = await _decode(change.doc);
    final Box<Map<String, dynamic>> box = await _dataBox(familyId);
    final Map<String, dynamic>? local = box.get(id);

    if (local != null) {
      final DateTime? localUpdated = parseNullableDateTime(local['updatedAt']);
      final DateTime? remoteUpdated = parseNullableDateTime(remote['updatedAt']);
      if (local['_pending'] == true &&
          (remoteUpdated == null ||
              (localUpdated != null &&
                  remoteUpdated.isBefore(localUpdated)))) {
        final Map<String, dynamic> pending = Map<String, dynamic>.from(local)
          ..remove('_pending');
        final Map<String, dynamic> payload =
            await _encryption.encryptPayload(pending);
        await collectionRef(familyId)
            .doc(id)
            .set(payload, SetOptions(merge: true));
        return;
      }
      if (remoteUpdated != null &&
          localUpdated != null &&
          remoteUpdated.isBefore(localUpdated)) {
        final Map<String, dynamic> payload =
            await _encryption.encryptPayload(Map<String, dynamic>.from(local)
              ..remove('_pending'));
        await collectionRef(familyId)
            .doc(id)
            .set(payload, SetOptions(merge: true));
        return;
      }
    }

    remote['_pending'] = false;
    await box.put(id, remote);
  }

  Future<Map<String, dynamic>> _decode(
      DocumentSnapshot<Map<String, dynamic>> doc) async {
    final Map<String, dynamic> decoded =
        await _encryption.decode(doc.data());
    decoded['id'] = doc.id;
    decoded.remove('enc');
    decoded['updatedAt'] ??= DateTime.now().toUtc().toIso8601String();
    decoded['createdAt'] ??= decoded['updatedAt'];
    return decoded;
  }

  List<T> _deserialize(Iterable<Map<String, dynamic>> values) {
    final List<T> items = values
        .map((Map<String, dynamic> value) =>
            fromMap(Map<String, dynamic>.from(value)))
        .toList();
    if (sorter != null) {
      items.sort(sorter);
    }
    return items;
  }
}

