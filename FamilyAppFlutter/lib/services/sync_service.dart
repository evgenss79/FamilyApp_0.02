import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/call_messages_repository.dart';
import '../repositories/calls_repository.dart';
import '../repositories/chat_messages_repository.dart';
import '../repositories/chats_repository.dart';
import '../repositories/events_repository.dart';
import '../repositories/friends_repository.dart';
import '../repositories/gallery_repository.dart';
import '../repositories/members_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/tasks_repository.dart';

class SyncService {
  SyncService({
    required this.familyId,
    required MembersRepository membersRepository,
    required TasksRepository tasksRepository,
    required EventsRepository eventsRepository,
    required FriendsRepository friendsRepository,
    required GalleryRepository galleryRepository,
    required ScheduleRepository scheduleRepository,
    required ChatsRepository chatsRepository,
    required ChatMessagesRepository chatMessagesRepository,
    required CallsRepository callsRepository,
    required CallMessagesRepository callMessagesRepository,
  })  : _membersRepository = membersRepository,
        _tasksRepository = tasksRepository,
        _eventsRepository = eventsRepository,
        _friendsRepository = friendsRepository,
        _galleryRepository = galleryRepository,
        _scheduleRepository = scheduleRepository,
        _chatsRepository = chatsRepository,
        _chatMessagesRepository = chatMessagesRepository,
        _callsRepository = callsRepository,
        _callMessagesRepository = callMessagesRepository;

  final String familyId;

  final MembersRepository _membersRepository;
  final TasksRepository _tasksRepository;
  final EventsRepository _eventsRepository;
  final FriendsRepository _friendsRepository;
  final GalleryRepository _galleryRepository;
  final ScheduleRepository _scheduleRepository;
  final ChatsRepository _chatsRepository;
  final ChatMessagesRepository _chatMessagesRepository;
  final CallsRepository _callsRepository;
  final CallMessagesRepository _callMessagesRepository;

  final List<StreamSubscription<dynamic>> _subscriptions =
      <StreamSubscription<dynamic>>[];

  Future<void> start() async {
    await Future.wait<void>(<Future<void>>[
      _membersRepository.pullRemote(familyId),
      _tasksRepository.pullRemote(familyId),
      _eventsRepository.pullRemote(familyId),
      _friendsRepository.pullRemote(familyId),
      _galleryRepository.pullRemote(familyId),
      _scheduleRepository.pullRemote(familyId),
      _chatsRepository.pullRemote(familyId),
      _callsRepository.pullRemote(familyId),
    ]);

    _subscriptions.add(_membersRepository.listenRemote(familyId));
    _subscriptions.add(_tasksRepository.listenRemote(familyId));
    _subscriptions.add(_eventsRepository.listenRemote(familyId));
    _subscriptions.add(_friendsRepository.listenRemote(familyId));
    _subscriptions.add(_galleryRepository.listenRemote(familyId));
    _subscriptions.add(_scheduleRepository.listenRemote(familyId));

    _subscriptions.add(
      _chatsRepository.listenRemote(
        familyId,
        onChange: (DocumentChange<Map<String, dynamic>> change) async {
          if (change.type == DocumentChangeType.removed) {
            await _chatMessagesRepository.cancelForChat(
              familyId,
              change.doc.id,
            );
            return;
          }
          await _chatMessagesRepository.listenForChat(familyId, change.doc.id);
          await _chatMessagesRepository.pullRemote(familyId, change.doc.id);
        },
      ),
    );

    _subscriptions.add(
      _callsRepository.listenRemote(
        familyId,
        onChange: (DocumentChange<Map<String, dynamic>> change) async {
          if (change.type == DocumentChangeType.removed) {
            await _callMessagesRepository.cancelForCall(
              familyId,
              change.doc.id,
            );
            return;
          }
          await _callMessagesRepository.listenForCall(familyId, change.doc.id);
          await _callMessagesRepository.pullRemote(familyId, change.doc.id);
        },
      ),
    );
  }

  Future<void> flush() async {
    await _membersRepository.pushPending(familyId);
    await _tasksRepository.pushPending(familyId);
    await _eventsRepository.pushPending(familyId);
    await _friendsRepository.pushPending(familyId);
    await _galleryRepository.pushPending(familyId);
    await _scheduleRepository.pushPending(familyId);
    await _chatsRepository.pushPending(familyId);
    await _callsRepository.pushPending(familyId);
    await _chatMessagesRepository.pushPending(familyId);
    await _callMessagesRepository.pushPending(familyId);
  }

  Future<void> dispose() async {
    for (final StreamSubscription<dynamic> sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    await _chatMessagesRepository.dispose();
    await _callMessagesRepository.dispose();
  }
}

