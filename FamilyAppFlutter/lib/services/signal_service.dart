import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:uuid/uuid.dart';

// ... (весь код класса ниже остаётся тот же, кроме исправленных строк)

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
              data['sdpMLineIndex'] as int?, // Указываем MLineIndex (camelCase)
            ));
          }
        }
      }
    });

    final answerSub = roomRef.snapshots().listen((doc) async {
      final data = doc.data();
      if (data == null) return;
      final answer = data['answer'];
      if (answer != null && (await pcAsCaller.getRemoteDescription()) == null) {
        await pcAsCaller.setRemoteDescription(RTCSessionDescription(
          answer['sdp'] as String,
          answer['type'] as String,
        ));
      }
    });
