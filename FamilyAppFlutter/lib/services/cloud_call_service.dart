import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'signal_service.dart';

/// Service managing WebRTC calls via Firebase rooms.
class CloudCallService {
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  final ready = ValueNotifier<bool>(false);
  final inCall = ValueNotifier<bool>(false);

  MediaStream? _localStream;
  RTCPeerConnection? _pc;
  SignalService? _signal;
  SignalSubscriptions? _subs;
  String? _roomId;
  bool _isCaller = false;

  Future<void> init() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    final media = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    _localStream = media;
    localRenderer.srcObject = media;
    ready.value = true;
  }

  Future<void> _ensurePc() async {
    if (_pc != null) return;
    final config = {
      'sdpSemantics': 'unified-plan',
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };
    final pc = await createPeerConnection(config);
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }
    pc.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };
    _pc = pc;
  }

  Future<String> createRoom() async {
    _signal = SignalService();
    await _ensurePc();
    _isCaller = true;
    final id = await _signal!.createRoom(pc: _pc!, localStream: _localStream!);
    _subs = await _signal!.wireIceAndAnswer(roomId: id, pcAsCaller: _pc!);
    _roomId = id;
    inCall.value = true;
    return id;
  }

  Future<void> joinRoom(String roomId) async {
    _signal = SignalService();
    await _ensurePc();
    _isCaller = false;
    await _signal!.joinRoom(roomId: roomId, pc: _pc!, localStream: _localStream!);
    _subs = await _signal!.wireIceAsCallee(roomId: roomId, pcAsCallee: _pc!);
    _roomId = roomId;
    inCall.value = true;
  }

  Future<void> toggleMute() async {
    for (var track in _localStream?.getAudioTracks() ?? []) {
      track.enabled = !track.enabled;
    }
  }

  Future<void> switchCamera() async {
    for (var track in _localStream?.getVideoTracks() ?? []) {
      await Helper.switchCamera(track);
    }
  }

  Future<void> hangup() async {
    try {
      if (_roomId != null && _signal != null) {
        await _signal!.hangup(_roomId!);
      }
    } catch (_) {}
    await _subs?.dispose();
    await _pc?.close();
    _pc = null;
    _subs = null;
    _roomId = null;
    inCall.value = false;
    remoteRenderer.srcObject = null;
  }

  String? get roomId => _roomId;
  bool get isCaller => _isCaller;

  Future<void> dispose() async {
    await hangup();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    await _localStream?.dispose();
  }
}
