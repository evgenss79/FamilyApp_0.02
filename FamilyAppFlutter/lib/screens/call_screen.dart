import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/conversation.dart';
import '../models/family_member.dart';
import '../providers/auth_provider.dart';
import '../providers/family_data.dart';
import '../services/call_service.dart';
import '../services/webrtc_service.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.conversation,
    required this.callType,
    this.isCaller = false,
  });

  final Conversation conversation;
  final String callType; // 'audio' or 'video'
  final bool isCaller;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  WebRtcSession? _session;
  bool _initializing = true;
  bool _closing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
  }

  @override
  void dispose() {
    final WebRtcSession? session = _session;
    if (session != null) {
      session.removeListener(_handleSessionUpdate);
      unawaited(session.release(notifyRemote: false));
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? familyId = auth.familyId;
    final String? memberId = auth.currentMember?.id;
    if (familyId == null || memberId == null) {
      setState(() {
        _error = context.tr('profileMissing');
        _initializing = false;
      });
      return;
    }
    final CallService callService = context.read<CallService>();
    final Conversation conversation = widget.conversation.copyWith(
      type: widget.conversation.type ?? widget.callType,
    );
    try {
      final WebRtcSession session = widget.isCaller
          ? await callService.startCall(
              familyId: familyId,
              conversation: conversation,
              memberId: memberId,
            )
          : await callService.joinCall(
              familyId: familyId,
              conversation: conversation,
              memberId: memberId,
            );
      if (!mounted) {
        unawaited(session.release(notifyRemote: false));
        return;
      }
      _attachSession(session);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to start call',
        name: 'CallScreen',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _initializing = false;
      });
    }
  }

  void _attachSession(WebRtcSession session) {
    _session = session;
    session.addListener(_handleSessionUpdate);
    session.addDisposeListener(() {
      session.removeListener(_handleSessionUpdate);
    });
    setState(() {
      _initializing = false;
    });
  }

  void _handleSessionUpdate() {
    if (!mounted || _session == null) {
      return;
    }
    final CallStatus status = _session!.status;
    if ((status == CallStatus.ended || status == CallStatus.failed) && !_closing) {
      _closing = true;
      final String message = status == CallStatus.failed
          ? context.tr('callStatusFailed')
          : context.tr('callStatusEnded');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          Navigator.of(context).maybePop();
        }
      });
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleEndTapped() async {
    if (_closing) {
      return;
    }
    _closing = true;
    await _endCall();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _endCall() async {
    final WebRtcSession? session = _session;
    if (session != null) {
      await session.hangUp();
      await session.release();
      _session = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final FamilyData familyData = context.watch<FamilyData>();
    final List<FamilyMember> participants = widget.conversation.participantIds
        .map(
          (String id) => familyData.members.firstWhere(
            (FamilyMember member) => member.id == id,
            orElse: () => FamilyMember(
              id: id,
              name: context.tr('unknownMemberLabel'),
            ),
          ),
        )
        .toList();
    final String names = participants
        .map((FamilyMember member) => member.name ?? context.tr('noNameLabel'))
        .join(', ');
    final String typeLabel = widget.callType == 'video'
        ? context.tr('videoLabel')
        : context.tr('audioLabel');
    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            context.loc
                .translateWithParams('callScreenTitle', {'type': typeLabel}),
          ),
        ),
        body: _buildBody(names),
      ),
    );
  }

  Widget _buildBody(String names) {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _CallErrorState(
        message: _error!,
        onClose: () {
          Navigator.of(context).pop();
        },
      );
    }
    final WebRtcSession? session = _session;
    if (session == null) {
      return _CallErrorState(
        message: context.tr('callStatusFailed'),
        onClose: () {
          Navigator.of(context).pop();
        },
      );
    }
    if (session.isVideoCall) {
      return _buildVideoBody(session, names);
    }
    return _buildAudioBody(session, names);
  }

  Widget _buildVideoBody(WebRtcSession session, String names) {
    final bool remoteReady =
        session.status == CallStatus.connected && session.remoteRenderer.srcObject != null;
    final double topPadding = MediaQuery.of(context).padding.top;
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: remoteReady
                ? RTCVideoView(
                    session.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  )
                : _buildStatusCenter(session, names, textColor: Colors.white),
          ),
          Positioned(
            right: 16,
            top: 16 + topPadding,
            width: 120,
            height: 160,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
                color: Colors.black45,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  session.localRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  mirror: true,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.only(bottom: 16),
              child: _buildControls(session),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioBody(WebRtcSession session, String names) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            CircleAvatar(
              radius: 56,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 48,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              names,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr(_statusKey(session.status)),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (session.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                session.errorMessage!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            SafeArea(
              minimum: const EdgeInsets.only(bottom: 16),
              child: _buildControls(session),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCenter(
    WebRtcSession session,
    String names, {
    Color? textColor,
  }) {
    final ThemeData theme = Theme.of(context);
    final Color effectiveColor = textColor ?? theme.colorScheme.onSurface;
    final List<Widget> children = <Widget>[
      Icon(
        session.isVideoCall ? Icons.videocam : Icons.call,
        size: 56,
        color: effectiveColor,
      ),
      const SizedBox(height: 16),
      Text(
        context.loc.translateWithParams('callingLabel', {'names': names}),
        style: theme.textTheme.titleMedium?.copyWith(color: effectiveColor),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      Text(
        context.tr(_statusKey(session.status)),
        style: theme.textTheme.titleLarge?.copyWith(color: effectiveColor),
        textAlign: TextAlign.center,
      ),
    ];
    if (session.errorMessage != null) {
      children.addAll(<Widget>[
        const SizedBox(height: 8),
        Text(
          session.errorMessage!,
          style:
              theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
          textAlign: TextAlign.center,
        ),
      ]);
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildControls(WebRtcSession session) {
    final bool dark = session.isVideoCall;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color defaultBackground =
        dark ? Colors.white.withOpacity(0.15) : scheme.primaryContainer;
    final Color defaultForeground =
        dark ? Colors.white : scheme.onPrimaryContainer;
    final List<Widget> buttons = <Widget>[
      _CallControlButton(
        icon: session.micEnabled ? Icons.mic : Icons.mic_off,
        label: session.micEnabled
            ? context.tr('muteMicrophone')
            : context.tr('unmuteMicrophone'),
        backgroundColor: defaultBackground,
        foregroundColor: defaultForeground,
        onPressed: () async {
          await session.toggleMute();
          if (mounted) {
            setState(() {});
          }
        },
      ),
    ];
    if (session.isVideoCall && session.canToggleVideo) {
      buttons.add(const SizedBox(width: 16));
      buttons.add(
        _CallControlButton(
          icon: session.videoEnabled ? Icons.videocam : Icons.videocam_off,
          label: session.videoEnabled
              ? context.tr('disableVideo')
              : context.tr('enableVideo'),
          backgroundColor: defaultBackground,
          foregroundColor: defaultForeground,
          onPressed: () async {
            await session.toggleVideo();
            if (mounted) {
              setState(() {});
            }
          },
        ),
      );
      buttons.add(const SizedBox(width: 16));
      buttons.add(
        _CallControlButton(
          icon: Icons.cameraswitch,
          label: context.tr('switchCamera'),
          backgroundColor: defaultBackground,
          foregroundColor: defaultForeground,
          onPressed: session.canToggleVideo ? session.switchCamera : null,
        ),
      );
    }
    buttons.add(const SizedBox(width: 16));
    buttons.add(
      _CallControlButton(
        icon: Icons.call_end,
        label: context.tr('endCallAction'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: _handleEndTapped,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      ),
    );
  }

  String _statusKey(CallStatus status) {
    switch (status) {
      case CallStatus.ringing:
        return 'callStatusRinging';
      case CallStatus.connecting:
        return 'callStatusConnecting';
      case CallStatus.connected:
        return 'callStatusConnected';
      case CallStatus.ended:
        return 'callStatusEnded';
      case CallStatus.failed:
        return 'callStatusFailed';
    }
  }
}

class _CallControlButton extends StatelessWidget {
  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final FutureOr<void> Function()? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(18),
          backgroundColor: backgroundColor ?? scheme.primary,
          foregroundColor: foregroundColor ?? scheme.onPrimary,
        ),
        onPressed: enabled
            ? () async {
                await onPressed?.call();
              }
            : null,
        child: Icon(icon, size: 24),
      ),
    );
  }
}

class _CallErrorState extends StatelessWidget {
  const _CallErrorState({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              context.tr('callStatusFailed'),
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onClose,
              child: Text(context.tr('closeAction')),
            ),
          ],
        ),
      ),
    );
  }
}
