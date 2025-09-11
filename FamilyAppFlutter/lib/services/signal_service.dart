import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

class SignalService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _rooms => _db.collection('rooms');

  /// Создает комнату и публикует offer
  Future<String> createRoom({
    required RTCPeerConnection pc,
    required MediaStream localStream,
  }) async {
    final roomId = _uuid.v4();
    final roomRef = _rooms.doc(roomId);

    await roomRef.set({'createdAt': FieldValue.serverTimestamp(), 'active': true});

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);
    await roomRef.update({'offer': offer.toMap()});

    return roomId;
  }

  /// Подключается к существующей комнате, выставляет remote offer и публикует answer
  Future<void> joinRoom({
    required String roomId,
    required RTCPeerConnection pc,
    required MediaStream localStream,
  }) async {
    final roomRef = _rooms.doc(roomId);
    final roomSnap = await roomRef.get();
    if (!roomSnap.exists) throw StateError('Room not found: $roomId');

    final data = roomSnap.data()!;
    final offer = data['offer'];
    if (offer == null) throw StateError('Room has no offer');

    await pc.setRemoteDescription(RTCSessionDescription(
      offer['sdp'] as String,
      offer['type'] as String,
    ));

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    await roomRef.update({'answer': answer.toMap()});
  }

  /// Caller: ICE + ожидание answer (в Firestore)
  Future<SignalSubscriptions> wireIceAndAnswer({
    required String roomId,
    required RTCPeerConnection pcAsCaller,
  }) async {
    final roomRef = _rooms.doc(roomId);
    final callerCandidates = roomRef.collection('callerCandidates');
    final calleeCandidates = roomRef.collection('calleeCandidates');

    pcAsCaller.onIceCandidate = (RTCIceCandidate candidate) async {
      if (candidate.candidate != null) {
        await callerCandidates.add(candidate.toMap());
      }
    };

    final calleeSub = calleeCandidates.snapshots().listen((snapshot) async {
      for (final doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data();
          if (data != null) {
            await pcAsCaller.addCandidate(RTCIceCandidate(
              data['candidate'] as String?,
              data['sdpMid'] as String?,
              data['sdpMLineIndex'] as int?, // ВАЖНО: правильное поле
            ));
          }
        }
      }
    });

    final answerSub = roomRef.snapshots().listen((doc) async {
      final data = doc.data();
      if (data == null) return;
      final answer = data['answer'];
      final rd = await pcAsCaller.getRemoteDescription();
      if (answer != null && rd == null) {
        await pcAsCaller.setRemoteDescription(RTCSessionDescription(
          answer['sdp'] as String,
          answer['type'] as String,
        ));
      }
    });

    return SignalSubscriptions(
      onDispose: () async {
        await answerSub.cancel();
        await calleeSub.cancel();
      },
      addCalleeCandidate: (c) async => calleeCandidates.add(c.toMap()),
      addCallerCandidate: (c) async => callerCandidates.add(c.toMap()),
      roomRef: roomRef,
    );
  }

  /// Callee: ICE при входе
  Future<SignalSubscriptions> wireIceAsCallee({
    required String roomId,
    required RTCPeerConnection pcAsCallee,
  }) async {
    final roomRef = _rooms.doc(roomId);
    final callerCandidates = roomRef.collection('callerCandidates');
    final calleeCandidates = roomRef.collection('calleeCandidates');

    pcAsCallee.onIceCandidate = (RTCIceCandidate candidate) async {
      if (candidate.candidate != null) {
        await calleeCandidates.add(candidate.toMap());
      }
    };

    final callerSub = callerCandidates.snapshots().listen((snapshot) async {
      for (final doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final data = doc.doc.data();
          if (data != null) {
            await pcAsCallee.addCandidate(RTCIceCandidate(
              data['candidate'] as String?,
              data['sdpMid'] as String?,
              data['sdpMLineIndex'] as int?,
            ));
          }
        }
      }
    });

    return SignalSubscriptions(
      onDispose: () async => callerSub.cancel(),
      addCalleeCandidate: (c) async => calleeCandidates.add(c.toMap()),
      addCallerCandidate: (c) async => callerCandidates.add(c.toMap()),
      roomRef: roomRef,
    );
  }

  Future<void> hangup(String roomId) async {
    final roomRef = _rooms.doc(roomId);
    final callerCandidates = roomRef.collection('callerCandidates');
    final calleeCandidates = roomRef.collection('calleeCandidates');

    final batch = _db.batch();
    for (final d in (await callerCandidates.get()).docs) {
      batch.delete(d.reference);
    }
    for (final d in (await calleeCandidates.get()).docs) {
      batch.delete(d.reference);
    }
    batch.update(roomRef, {'active': false});
    await batch.commit();
  }
}

class SignalSubscriptions {
  final Future<void> Function() onDispose;
  final Future<void> Function(RTCIceCandidate) addCalleeCandidate;
  final Future<void> Function(RTCIceCandidate) addCallerCandidate;
  final DocumentReference<Map<String, dynamic>> roomRef;

  SignalSubscriptions({
    required this.onDispose,
    required this.addCalleeCandidate,
    required this.addCallerCandidate,
    required this.roomRef,
  });

  Future<void> dispose() => onDispose();
}

extension _SdpExt on RTCSessionDescription {
  Map<String, dynamic> toMap() => {'sdp': sdp, 'type': type};
}

extension _IceExt on RTCIceCandidate {
  Map<String, dynamic> toMap() =>
      {'candidate': candidate, 'sdpMid': sdpMid, 'sdpMLineIndex': sdpMLineIndex};
}
