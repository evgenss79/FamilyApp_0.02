import 'dart:io';

import 'package:family_app_flutter/main.dart';
import 'package:family_app_flutter/models/conversation.dart';
import 'package:family_app_flutter/models/event.dart';
import 'package:family_app_flutter/models/family_member.dart';
import 'package:family_app_flutter/models/friend.dart';
import 'package:family_app_flutter/models/gallery_item.dart';
import 'package:family_app_flutter/models/message.dart';
import 'package:family_app_flutter/models/schedule_item.dart';
import 'package:family_app_flutter/models/task.dart';
import 'package:family_app_flutter/providers/language_provider.dart';
import 'package:family_app_flutter/services/firestore_service.dart';
import 'package:family_app_flutter/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MyApp builds with fake Firestore/Storage services',
      (WidgetTester tester) async {
    final LanguageProvider languageProvider = LanguageProvider();

    await tester.pumpWidget(
      MyApp(
        firestore: _FakeFirestoreService(),
        storage: _FakeStorageService(),
        languageProvider: languageProvider,
      ),
    );

    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

class _FakeFirestoreService implements FirestoreService {
  @override
  Future<void> replayPendingOperations() async {}

  @override
  Future<List<FamilyMember>> loadCachedMembers(String familyId) async =>
      const <FamilyMember>[];

  @override
  Future<List<Task>> loadCachedTasks(String familyId) async => const <Task>[];

  @override
  Future<List<Event>> loadCachedEvents(String familyId) async =>
      const <Event>[];

  @override
  Future<List<ScheduleItem>> loadCachedSchedule(String familyId) async =>
      const <ScheduleItem>[];

  @override
  Future<List<Friend>> loadCachedFriends(String familyId) async =>
      const <Friend>[];

  @override
  Future<List<GalleryItem>> loadCachedGallery(String familyId) async =>
      const <GalleryItem>[];

  @override
  Future<List<Conversation>> loadCachedConversations(String familyId) async =>
      const <Conversation>[];

  @override
  Future<List<Message>> loadCachedMessages(
    String familyId,
    String conversationId,
  ) async =>
      const <Message>[];

  @override
  Stream<List<FamilyMember>> watchMembers(String familyId) =>
      Stream<List<FamilyMember>>.value(const <FamilyMember>[]);

  @override
  Future<void> createFamilyMember(String familyId, FamilyMember member) async {}

  @override
  Future<void> updateFamilyMember(String familyId, FamilyMember member) async {}

  @override
  Future<void> deleteFamilyMember(String familyId, String memberId) async {}

  @override
  Stream<List<Task>> watchTasks(String familyId) =>
      Stream<List<Task>>.value(const <Task>[]);

  @override
  Future<void> createTask(String familyId, Task task) async {}

  @override
  Future<void> updateTask(String familyId, Task task) async {}

  @override
  Future<void> deleteTask(String familyId, String taskId) async {}

  @override
  Stream<List<Event>> watchEvents(String familyId) =>
      Stream<List<Event>>.value(const <Event>[]);

  @override
  Future<void> createEvent(String familyId, Event event) async {}

  @override
  Future<void> updateEvent(String familyId, Event event) async {}

  @override
  Future<void> deleteEvent(String familyId, String eventId) async {}

  @override
  Stream<List<ScheduleItem>> watchSchedule(String familyId) =>
      Stream<List<ScheduleItem>>.value(const <ScheduleItem>[]);

  @override
  Future<void> createScheduleItem(String familyId, ScheduleItem item) async {}

  @override
  Future<void> deleteScheduleItem(String familyId, String itemId) async {}

  @override
  Stream<List<Friend>> watchFriends(String familyId) =>
      Stream<List<Friend>>.value(const <Friend>[]);

  @override
  Future<void> upsertFriend(String familyId, Friend friend) async {}

  @override
  Future<void> deleteFriend(String familyId, String friendId) async {}

  @override
  Stream<List<GalleryItem>> watchGallery(String familyId) =>
      Stream<List<GalleryItem>>.value(const <GalleryItem>[]);

  @override
  Future<void> upsertGalleryItem(String familyId, GalleryItem item) async {}

  @override
  Future<void> deleteGalleryItem(String familyId, String itemId) async {}

  @override
  Stream<List<Conversation>> watchConversations(String familyId) =>
      Stream<List<Conversation>>.value(const <Conversation>[]);

  @override
  Future<Conversation> createConversation({
    required String familyId,
    required Conversation conversation,
  }) async =>
      conversation;

  @override
  Future<void> updateConversation({
    required String familyId,
    required Conversation conversation,
  }) async {}

  @override
  Future<void> deleteConversation(String familyId, String conversationId) async {}

  @override
  Stream<List<Message>> watchMessages({
    required String familyId,
    required String conversationId,
    int limit = 50,
  }) =>
      Stream<List<Message>>.value(const <Message>[]);

  @override
  Future<Message> sendMessage({
    required String familyId,
    required String conversationId,
    required Message draft,
  }) async =>
      draft;

  @override
  Future<void> updateMessageStatus({
    required String familyId,
    required String conversationId,
    required Message message,
    required MessageStatus status,
  }) async {}

  @override
  Future<void> deleteMessage({
    required String familyId,
    required String conversationId,
    required String messageId,
  }) async {}
}

class _FakeStorageService implements StorageService {
  static const StorageUploadResult _empty =
      StorageUploadResult(downloadUrl: '', storagePath: '');

  @override
  Future<StorageUploadResult> uploadMemberAvatar({
    required String familyId,
    required File file,
  }) async =>
      _empty;

  @override
  Future<StorageUploadResult> uploadGalleryItem({
    required String familyId,
    required File file,
  }) async =>
      _empty;

  @override
  Future<StorageUploadResult> uploadChatAttachment({
    required String familyId,
    required String conversationId,
    required File file,
  }) async =>
      _empty;

  @override
  Future<void> deleteByPath(String storagePath) async {}

  @override
  Future<void> deleteByUrl(String url) async {}
}
