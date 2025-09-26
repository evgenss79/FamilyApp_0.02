import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/conversation.dart';
import '../repositories/calls_repository.dart';
import 'webrtc_service.dart';

class CallService {
  CallService({
    FirebaseFirestore? firestore,
    CallsRepository? callsRepository,
    WebRtcService? webRtcService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _callsRepository = callsRepository ?? CallsRepository(),
        _webrtc = webRtcService ?? WebRtcService();

  final FirebaseFirestore _firestore;
  final CallsRepository _callsRepository;
  final WebRtcService _webrtc;

  final Map<WebRtcSession, _CallContext> _contexts =
      <WebRtcSession, _CallContext>{};

  Future<WebRtcSession> startCall({
    required String familyId,
    required Conversation conversation,
    required String memberId,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final bool enableVideo = (conversation.type ?? '') == 'video';
    final List<String> participantIds =
        List<String>.from(conversation.participantIds);
    if (!participantIds.contains(memberId)) {
      participantIds.insert(0, memberId);
    }
    final Conversation normalized = conversation.copyWith(
      participantIds: participantIds,
      createdBy: memberId,
      updatedAt: now,
      status: 'ringing',
      type: conversation.type ?? (enableVideo ? 'video' : 'audio'),
    );
    final DocumentReference<Map<String, dynamic>> doc =
        _callDoc(familyId, normalized.id);
    // ANDROID-ONLY FIX: seed the Android signalling document before creating the peer connection.
    await doc.set(<String, Object?>{
      'id': normalized.id,
      'familyId': familyId,
      'title': normalized.title,
      'participants': participantIds,
      'type': normalized.type,
      'createdBy': memberId,
      'status': 'ringing',
      'createdAt': Timestamp.fromDate(normalized.createdAt.toUtc()),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _callsRepository.saveLocal(familyId, normalized, pending: false);
    final WebRtcSession session = await _webrtc.startSession(
      callDoc: doc,
      familyId: familyId,
      callId: normalized.id,
      memberId: memberId,
      isCaller: true,
      enableVideo: enableVideo,
    );
    _registerSession(session, familyId, normalized);
    return session;
  }

  Future<WebRtcSession> joinCall({
    required String familyId,
    required Conversation conversation,
    required String memberId,
  }) async {
    final DateTime now = DateTime.now().toUtc();
    final bool enableVideo = (conversation.type ?? '') == 'video';
    final List<String> participantIds =
        List<String>.from(conversation.participantIds);
    if (!participantIds.contains(memberId)) {
      participantIds.add(memberId);
    }
    final Conversation normalized = conversation.copyWith(
      participantIds: participantIds,
      updatedAt: now,
      status: 'connecting',
      type: conversation.type ?? (enableVideo ? 'video' : 'audio'),
    );
    final DocumentReference<Map<String, dynamic>> doc =
        _callDoc(familyId, normalized.id);
    await doc.set(<String, Object?>{
      'participants': FieldValue.arrayUnion(<String>[memberId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _callsRepository.saveLocal(familyId, normalized, pending: false);
    final WebRtcSession session = await _webrtc.startSession(
      callDoc: doc,
      familyId: familyId,
      callId: normalized.id,
      memberId: memberId,
      isCaller: false,
      enableVideo: enableVideo,
    );
    _registerSession(session, familyId, normalized);
    return session;
  }

  Future<void> dispose() async {
    if (_contexts.isNotEmpty) {
      final List<WebRtcSession> sessions =
          List<WebRtcSession>.from(_contexts.keys);
      for (final WebRtcSession session in sessions) {
        await session.release(notifyRemote: false);
      }
      _contexts.clear();
    }
    await _webrtc.dispose();
  }

  void _registerSession(
    WebRtcSession session,
    String familyId,
    Conversation conversation,
  ) {
    final _CallContext context = _CallContext(
      familyId: familyId,
      conversation: conversation,
    );
    _contexts[session] = context;
    void listener() => _onSessionChanged(session);
    session.addListener(listener);
    context.removeListener = () {
      session.removeListener(listener);
    };
    session.addDisposeListener(() {
      context.removeListener?.call();
      _contexts.remove(session);
    });
    _onSessionChanged(session);
  }

  void _onSessionChanged(WebRtcSession session) {
    final _CallContext? context = _contexts[session];
    if (context == null) {
      return;
    }
    final CallStatus status = session.status;
    final DateTime now = DateTime.now().toUtc();
    final Conversation updated = context.conversation.copyWith(
      status: _statusLabel(status),
      updatedAt: now,
      lastMessageTime:
          status == CallStatus.connected ? now : context.conversation.lastMessageTime,
      endedAt: (status == CallStatus.ended || status == CallStatus.failed)
          ? now
          : context.conversation.endedAt,
    );
    context.conversation = updated;
    unawaited(_callsRepository.saveLocal(context.familyId, updated, pending: false));
  }

  String _statusLabel(CallStatus status) {
    switch (status) {
      case CallStatus.ringing:
        return 'ringing';
      case CallStatus.connecting:
        return 'connecting';
      case CallStatus.connected:
        return 'connected';
      case CallStatus.ended:
        return 'ended';
      case CallStatus.failed:
        return 'failed';
    }
  }

  DocumentReference<Map<String, dynamic>> _callDoc(
    String familyId,
    String callId,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('calls')
        .doc(callId);
  }
}

class _CallContext {
  _CallContext({required this.familyId, required this.conversation});

  final String familyId;
  Conversation conversation;
  VoidCallback? removeListener;
}
