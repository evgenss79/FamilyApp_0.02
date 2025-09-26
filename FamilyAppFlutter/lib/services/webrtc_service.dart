import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

enum CallStatus { ringing, connecting, connected, ended, failed }

/// Handles lifecycle of active WebRTC sessions using Firestore as the
/// signalling transport.
class WebRtcService {
  WebRtcService();
  final Set<WebRtcSession> _sessions = <WebRtcSession>{};

  Future<WebRtcSession> startSession({
    required DocumentReference<Map<String, dynamic>> callDoc,
    required String familyId,
    required String callId,
    required String memberId,
    required bool isCaller,
    required bool enableVideo,
  }) async {
    final WebRtcSession session = WebRtcSession(
      callDoc: callDoc,
      familyId: familyId,
      callId: callId,
      memberId: memberId,
      isCaller: isCaller,
      enableVideo: enableVideo,
    );
    _sessions.add(session);
    session.addDisposeListener(() {
      _sessions.remove(session);
    });
    await session.initialize();
    return session;
  }

  Future<void> dispose() async {
    if (_sessions.isEmpty) {
      return;
    }
    await Future.wait(
      _sessions.map(
        (WebRtcSession session) => session.release(notifyRemote: false),
      ),
    );
    _sessions.clear();
  }
}

class WebRtcSession extends ChangeNotifier {
  WebRtcSession({
    required DocumentReference<Map<String, dynamic>> callDoc,
    required this.familyId,
    required this.callId,
    required this.memberId,
    required this.isCaller,
    required bool enableVideo,
  })  : _callDoc = callDoc,
        _enableVideo = enableVideo,
        localRenderer = RTCVideoRenderer(),
        remoteRenderer = RTCVideoRenderer();

  final DocumentReference<Map<String, dynamic>> _callDoc;
  final bool isCaller;
  final String familyId;
  final String callId;
  final String memberId;
  final bool _enableVideo;
  final RTCVideoRenderer localRenderer;
  final RTCVideoRenderer remoteRenderer;

  CallStatus _status = CallStatus.connecting;
  String? _errorMessage;
  bool _micEnabled = true;
  bool _videoEnabled = false;
  bool _initialised = false;
  bool _closed = false;
  bool _released = false;
  bool _remoteDescriptionSet = false;
  bool _answerPublished = false;

  MediaStream? _localStream;
  MediaStream? _remoteStream;
  MediaStreamTrack? _localVideoTrack;
  RTCPeerConnection? _peerConnection;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSubscription;
  final Set<String> _appliedCandidateKeys = <String>{};
  final List<VoidCallback> _disposeListeners = <VoidCallback>[];

  CallStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get micEnabled => _micEnabled;
  bool get videoEnabled => _videoEnabled;
  bool get canToggleVideo => _localVideoTrack != null;
  bool get isVideoCall => _enableVideo;

  Future<void> initialize() async {
    if (_initialised) {
      return;
    }
    _initialised = true;
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
      await _ensurePermissions();
      await _prepareMedia();
      await _createPeerConnection();
      await _beginSignalling();
    } catch (error, stackTrace) {
      _fail(error, stackTrace);
      rethrow;
    }
  }

  Future<void> hangUp({bool notifyRemote = true}) async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _callSubscription?.cancel();
    _callSubscription = null;
    try {
      await _peerConnection?.close();
    } catch (error, stackTrace) {
      developer.log(
        'Unable to close peer connection',
        name: 'WebRtcSession',
        error: error,
        stackTrace: stackTrace,
      );
    }
    _peerConnection = null;
    await _localStream?.dispose();
    await _remoteStream?.dispose();
    _localStream = null;
    _remoteStream = null;
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    if (notifyRemote) {
      await _callDoc.set(<String, Object?>{
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    _updateStatus(CallStatus.ended);
  }

  Future<void> release({bool notifyRemote = false}) async {
    if (_released) {
      return;
    }
    _released = true;
    if (!_closed) {
      await hangUp(notifyRemote: notifyRemote);
    }
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    for (final VoidCallback listener in _disposeListeners) {
      listener();
    }
    _disposeListeners.clear();
    super.dispose();
  }

  Future<void> toggleMute() async {
    if (_localStream == null) {
      return;
    }
    final bool next = !_micEnabled;
    for (final MediaStreamTrack track in _localStream!.getAudioTracks()) {
      track.enabled = next;
    }
    _micEnabled = next;
    notifyListeners();
  }

  Future<void> toggleVideo() async {
    final MediaStreamTrack? track = _localVideoTrack;
    if (track == null) {
      return;
    }
    final bool next = !_videoEnabled;
    track.enabled = next;
    _videoEnabled = next;
    notifyListeners();
  }

  Future<void> switchCamera() async {
    final MediaStreamTrack? track = _localVideoTrack;
    if (track == null) {
      return;
    }
    await Helper.switchCamera(track);
  }

  void addDisposeListener(VoidCallback listener) {
    _disposeListeners.add(listener);
  }

  Future<void> _ensurePermissions() async {
    final List<Permission> permissions = <Permission>[Permission.microphone];
    if (_enableVideo) {
      permissions.add(Permission.camera);
    }
    final Map<Permission, PermissionStatus> results =
        await permissions.request();
    final bool granted = results.values.every((PermissionStatus status) {
      return status.isGranted || status.isLimited;
    });
    if (!granted) {
      // ANDROID-ONLY FIX: request runtime microphone/camera permissions before establishing Android peer connection.
      throw StateError('Microphone or camera permission denied');
    }
  }

  Future<void> _prepareMedia() async {
    final Map<String, dynamic> constraints = <String, dynamic>{
      'audio': true,
      'video': _enableVideo
          ? <String, dynamic>{
              'facingMode': 'user',
            }
          : false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(constraints);
    localRenderer.srcObject = _localStream;
    _localVideoTrack =
        _localStream!.getVideoTracks().isEmpty ? null : _localStream!.getVideoTracks().first;
    _videoEnabled = _localVideoTrack?.enabled ?? false;
  }

  Future<void> _createPeerConnection() async {
    const Map<String, dynamic> configuration = <String, dynamic>{
      'iceServers': <Map<String, dynamic>>[
        <String, dynamic>{'urls': 'stun:stun.l.google.com:19302'},
        <String, dynamic>{'urls': 'stun:stun1.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    };
    const Map<String, dynamic> constraints = <String, dynamic>{
      'mandatory': <String, dynamic>{},
      'optional': <Map<String, dynamic>>[
        <String, dynamic>{'DtlsSrtpKeyAgreement': true},
      ],
    };
    _peerConnection = await createPeerConnection(configuration, constraints);
    final MediaStream? stream = _localStream;
    if (stream != null) {
      for (final MediaStreamTrack track in stream.getTracks()) {
        await _peerConnection!.addTrack(track, stream);
      }
    }
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams.first;
        remoteRenderer.srcObject = _remoteStream;
      }
    };
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _updateStatus(CallStatus.connected);
        _setRemoteStatus('connected');
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _fail(StateError('Peer connection failed'));
      } else if (state ==
              RTCPeerConnectionState.RTCPeerConnectionStateClosed ||
          state ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        if (!_closed) {
          _updateStatus(CallStatus.ended);
        }
      }
    };
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) async {
      await _sendCandidate(candidate);
    };
    _peerConnection!.onIceConnectionState =
        (RTCIceConnectionState state) {
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        _fail(StateError('ICE gathering failed'));
      }
    };
  }

  Future<void> _beginSignalling() async {
    _callSubscription = _callDoc.snapshots().listen(
      (DocumentSnapshot<Map<String, dynamic>> snapshot) {
        unawaited(_handleSnapshot(snapshot));
      },
      onError: (Object error, StackTrace stackTrace) {
        _fail(error, stackTrace);
      },
    );
    if (isCaller) {
      await _createOffer();
    } else {
      _updateStatus(CallStatus.connecting);
    }
  }

  Future<void> _createOffer() async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      throw StateError('Peer connection not ready');
    }
    final RTCSessionDescription description = await pc.createOffer(<String, dynamic>{
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': _enableVideo,
    });
    await pc.setLocalDescription(description);
    await _callDoc.set(<String, Object?>{
      'offer': <String, Object?>{
        'sdp': description.sdp,
        'type': description.type,
      },
      'status': 'ringing',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _updateStatus(CallStatus.ringing);
  }

  Future<void> _createAnswer() async {
    if (_answerPublished) {
      return;
    }
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      return;
    }
    final RTCSessionDescription answer = await pc.createAnswer(<String, dynamic>{
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': _enableVideo,
    });
    await pc.setLocalDescription(answer);
    await _callDoc.set(<String, Object?>{
      'answer': <String, Object?>{
        'sdp': answer.sdp,
        'type': answer.type,
      },
      'status': 'connecting',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _answerPublished = true;
    _updateStatus(CallStatus.connecting);
  }

  Future<void> _handleSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (_closed) {
      return;
    }
    if (!snapshot.exists) {
      await hangUp(notifyRemote: false);
      return;
    }
    final Map<String, dynamic>? data = snapshot.data();
    if (data == null) {
      return;
    }
    final String? remoteStatus = data['status'] as String?;
    if (remoteStatus == 'ended' && !_closed) {
      await hangUp(notifyRemote: false);
      return;
    }
    if (!_remoteDescriptionSet) {
      if (!isCaller) {
        final Map<String, dynamic>? offer = _castToMap(data['offer']);
        if (offer != null) {
          await _applyOffer(offer);
        }
      } else {
        final Map<String, dynamic>? answer = _castToMap(data['answer']);
        if (answer != null) {
          await _applyAnswer(answer);
        }
      }
    }
    await _consumeRemoteCandidates(data);
  }

  Future<void> _applyOffer(Map<String, dynamic> payload) async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      return;
    }
    if (_remoteDescriptionSet) {
      return;
    }
    final RTCSessionDescription description = RTCSessionDescription(
      payload['sdp'] as String? ?? '',
      payload['type'] as String? ?? 'offer',
    );
    await pc.setRemoteDescription(description);
    _remoteDescriptionSet = true;
    await _createAnswer();
  }

  Future<void> _applyAnswer(Map<String, dynamic> payload) async {
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      return;
    }
    if (_remoteDescriptionSet) {
      return;
    }
    final RTCSessionDescription description = RTCSessionDescription(
      payload['sdp'] as String? ?? '',
      payload['type'] as String? ?? 'answer',
    );
    await pc.setRemoteDescription(description);
    _remoteDescriptionSet = true;
    _updateStatus(CallStatus.connecting);
  }

  Future<void> _consumeRemoteCandidates(Map<String, dynamic> data) async {
    final String field = isCaller ? 'calleeCandidates' : 'callerCandidates';
    final List<dynamic>? candidates = data[field] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      return;
    }
    final RTCPeerConnection? pc = _peerConnection;
    if (pc == null) {
      return;
    }
    for (final dynamic entry in candidates) {
      final Map<String, dynamic>? candidate = _castToMap(entry);
      if (candidate == null) {
        continue;
      }
      final String candidateKey = _candidateKey(candidate);
      if (_appliedCandidateKeys.contains(candidateKey)) {
        continue;
      }
      _appliedCandidateKeys.add(candidateKey);
      try {
        await pc.addCandidate(
          RTCIceCandidate(
            candidate['candidate'] as String?,
            candidate['sdpMid'] as String?,
            (candidate['sdpMLineIndex'] as num?)?.toInt(),
          ),
        );
      } catch (error, stackTrace) {
        _fail(error, stackTrace);
      }
    }
  }

  Future<void> _sendCandidate(RTCIceCandidate candidate) async {
    if (candidate.candidate == null || candidate.candidate!.isEmpty) {
      return;
    }
    final Map<String, Object?> payload = <String, Object?>{
      'candidate': candidate.candidate,
      'sdpMid': candidate.sdpMid,
      'sdpMLineIndex': candidate.sdpMLineIndex,
      'ts': Timestamp.now(),
    };
    final String field = isCaller ? 'callerCandidates' : 'calleeCandidates';
    await _callDoc.set(<String, Object?>{
      field: FieldValue.arrayUnion(<Map<String, Object?>>[payload]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _setRemoteStatus(String status) {
    unawaited(_callDoc.set(<String, Object?>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)));
  }

  void _updateStatus(CallStatus next) {
    if (_status == next) {
      return;
    }
    _status = next;
    notifyListeners();
  }

  void _fail(Object error, [StackTrace? stackTrace]) {
    if (_status == CallStatus.failed || _status == CallStatus.ended) {
      return;
    }
    _errorMessage = error.toString();
    developer.log(
      'WebRTC session error',
      name: 'WebRtcSession',
      error: error,
      stackTrace: stackTrace,
    );
    _updateStatus(CallStatus.failed);
  }

  Map<String, dynamic>? _castToMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map<Object?, Object?>) {
      return value.map((Object? key, Object? value) {
        return MapEntry(key?.toString() ?? '', value);
      });
    }
    return null;
  }

  String _candidateKey(Map<String, dynamic> value) {
    final String candidate = value['candidate']?.toString() ?? '';
    final String sdpMid = value['sdpMid']?.toString() ?? '';
    final String lineIndex = value['sdpMLineIndex']?.toString() ?? '';
    return '$candidate|$sdpMid|$lineIndex';
  }
}
