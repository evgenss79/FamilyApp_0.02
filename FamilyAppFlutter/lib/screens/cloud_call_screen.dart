import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/cloud_call_service.dart';
import '../services/call_service.dart';

/// Screen for making cloud-based WebRTC calls using Firestore for signaling.
///
/// This screen allows users to create or join a room for video calls. It checks whether
/// Firebase is properly initialized and provides controls for starting and ending the call,
/// toggling the microphone and switching cameras.
class CloudCallScreen extends StatefulWidget {
  const CloudCallScreen({super.key});

  static const routeName = '/cloud-call';

  @override
  State<CloudCallScreen> createState() => _CloudCallScreenState();
}

class _CloudCallScreenState extends State<CloudCallScreen> {
  final CloudCallService _call = CloudCallService();
  final TextEditingController _joinController = TextEditingController();

  bool _firebaseOk = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      // Determine if Firebase has been configured and is available.
      _firebaseOk = Firebase.apps.isNotEmpty;
      if (_firebaseOk) {
        // Perform a basic Firestore operation to ensure it's accessible.
        await FirebaseFirestore.instance.terminate();
        await FirebaseFirestore.instance.clearPersistence();
      }
      await _call.init();
      if (mounted) setState(() {});
    } catch (e) {
      _error = 'Ошибка инициализации: $e';
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _call.dispose();
    _joinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Облачный звонок')),
        body: Center(child: Text(_error!)),
      );
    }
    if (!_firebaseOk) {
      return Scaffold(
        appBar: AppBar(title: const Text('Облачный звонок')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: const [
              Text(
                'Firebase не сконфигурирован.\n'
                '1) Выполните `flutterfire configure` и добавьте google-services.json / GoogleService-Info.plist.\n'
                '2) Повторно соберите приложение.\n'
                'Локальные чаты и локальный звонок доступны без Firebase.',
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Облачный звонок (комната)')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    color: Colors.black12,
                    child: RTCVideoViewWrapper(renderer: _call.localRenderer, label: 'Local'),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    color: Colors.black12,
                    child: RTCVideoViewWrapper(renderer: _call.remoteRenderer, label: 'Remote'),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: _call.inCall,
                    builder: (_, inCall, __) {
                      return Column(
                        children: [
                          if (!inCall)
                            Row(
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: () async {
                                      final id = await _call.createRoom();
                                      if (!mounted) return;
                                      await showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Комната создана'),
                                          content: SelectableText('Передайте roomId собеседнику:\n\n\$id'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add_box),
                                    label: const Text('Создать комнату'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _joinController,
                                    decoration: const InputDecoration(
                                      labelText: 'Room ID',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () async {
                                    final id = _joinController.text.trim();
                                    if (id.isEmpty) return;
                                    await _call.joinRoom(id);
                                    if (!mounted) return;
                                    setState(() {});
                                  },
                                  child: const Text('Войти'),
                                ),
                              ],
                            ),
                          if (inCall)
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: SelectableText('Room: ' + (_call.roomId ?? '-')),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton.filledTonal(
                                  onPressed: () => _call.toggleMute(),
                                  icon: const Icon(Icons.mic_off),
                                  tooltip: 'Микрофон вкл/выкл',
                                ),
                                const SizedBox(width: 12),
                                IconButton.filledTonal(
                                  onPressed: () => _call.switchCamera(),
                                  icon: const Icon(Icons.cameraswitch),
                                  tooltip: 'Сменить камеру',
                                ),
                                const SizedBox(width: 12),
                                IconButton.filled(
                                  onPressed: () async {
                                    await _call.hangup();
                                    if (!mounted) return;
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.call_end),
                                  tooltip: 'Завершить',
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
