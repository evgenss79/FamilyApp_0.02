import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Service handling local WebRTC loopback calls.
class CallService {
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();

  final ready = ValueNotifier<bool>(false);

  MediaStream? _localStream;
  RTCPeerConnection? _pc1;
  RTCPeerConnection? _pc2;

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

  Future<void> startLoopback() async {
    await hangup();

    final config = {
      'sdpSemantics': 'unified-plan',
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _pc1 = await createPeerConnection(config);
    _pc2 = await createPeerConnection(config);

    // add local tracks to pc1
    for (var track in _localStream!.getTracks()) {
      await _pc1!.addTrack(track, _localStream!);
    }

    // remote renderer listens to pc2
    _pc2!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    // exchange ICE candidates
    _pc1!.onIceCandidate = (candidate) async {
      if (candidate != null) {
        await _pc2!.addCandidate(candidate);
      }
    };
    _pc2!.onIceCandidate = (candidate) async {
      if (candidate != null) {
        await _pc1!.addCandidate(candidate);
      }
    };

    final offer = await _pc1!.createOffer();
    await _pc1!.setLocalDescription(offer);
    await _pc2!.setRemoteDescription(offer);

    final answer = await _pc2!.createAnswer();
    await _pc2!.setLocalDescription(answer);
    await _pc1!.setRemoteDescription(answer);
  }

  Future<void> toggleMute() async {
    if (_localStream == null) return;
    for (var track in _localStream!.getAudioTracks()) {
      track.enabled = !track.enabled;
    }
  }

  Future<void> switchCamera() async {
    for (var track in _localStream?.getVideoTracks() ?? []) {
      await Helper.switchCamera(track);
    }
  }

  Future<void> hangup() async {
    await _pc1?.close();
    await _pc2?.close();
    _pc1 = null;
    _pc2 = null;
    remoteRenderer.srcObject = null;
  }

  Future<void> dispose() async {
    await hangup();
    await localRenderer.dispose();
    await remoteRenderer.dispose();
    await _localStream?.dispose();
  }
}

/// Wrapper widget to display an RTCVideoRenderer with a label.
class RTCVideoViewWrapper extends StatelessWidget {
  final RTCVideoRenderer renderer;
  final String label;

  const RTCVideoViewWrapper({Key? key, required this.renderer, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RTCVideoView(renderer, mirror: true),
        Positioned(
          left: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.black54,
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
