import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../services/cloud_call_service.dart';
import '../services/call_service.dart';

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
      _firebaseOk = Firebase.apps.isNotEmpty;
      if (_firebaseOk) {
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
        appBar: AppBar(title: const Text('Облачный звонок (комната)')),
        body: Center(child: Text(_error!)),
      );
    }
    if (!_firebaseOk) {
      return Scaffold(
        appBar: AppBar(title: const Text('Облачный звонок (комната)')),
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
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RTCVideoViewWrapper(
                      renderer: _call.localRenderer,
                      label: 'Local',
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: RTCVideoViewWrapper(
                      renderer: _call.remoteRenderer,
                      label: 'Remote',
                    ),
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
                    builder: (context, inCall, _) {
                      if (inCall) {
                        return Row(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: SelectableText('Room: ' + (_call.roomId ?? '-')),
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: _call.toggleMute,
                              icon: const Icon(Icons.mic_off),
                              tooltip: 'Mute/unmute',
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: _call.switchCamera,
                              icon: const Icon(Icons.cameraswitch),
                              tooltip: 'Switch camera',
                            ),
                            const SizedBox(width: 12),
                            IconButton.filledTonal(
                              onPressed: () async {
                                await _call.hangup();
                                if (!mounted) return;
                                setState(() {});
                              },
                              icon: const Icon(Icons.call_end),
                              tooltip: 'Hang up',
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
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
                              child: const Text('Join'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () async {
                                final roomId = await _call.createRoom();
                                if (!mounted) return;
                                await showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Создана комната'),
                                    content: SelectableText('roomId: ' + (roomId ?? '-')),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                setState(() {});
                              },
                              child: const Text('Create'),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
