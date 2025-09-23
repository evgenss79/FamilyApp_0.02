import 'dart:io';

import 'package:family_app_flutter/main.dart';
import 'package:family_app_flutter/models/chat.dart';
import 'package:family_app_flutter/models/chat_message.dart';
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
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Создаём минимальный экземпляр приложения с пустым ChatProvider.
    final languageProvider = LanguageProvider();
    await tester.pumpWidget(
      MyApp(
        firestore: _FakeFirestoreService(),
        storage: _FakeStorageService(),
        languageProvider: languageProvider,
      ),
    );
    await tester.pump();
  });
}

class _FakeFirestoreService extends FirestoreService {
  @override
  Future<List<FamilyMember>> fetchFamilyMembers(String familyId) async =>
      const <FamilyMember>[];

  @override
  Future<void> upsertFamilyMember(String familyId, FamilyMember member) async {}

  @override
  Future<void> deleteFamilyMember(String familyId, String memberId) async {}

  @override
  Future<List<Task>> fetchTasks(String familyId) async => const <Task>[];

  @override
  Future<void> upsertTask(String familyId, Task task) async {}

  @override
  Future<void> deleteTask(String familyId, String taskId) async {}

  @override
  Future<List<Event>> fetchEvents(String familyId) async => const <Event>[];

  @override
  Future<void> upsertEvent(String familyId, Event event) async {}

  @override
  Future<void> deleteEvent(String familyId, String eventId) async {}

  @override
  Future<List<ScheduleItem>> fetchScheduleItems(String familyId) async =>
      const <ScheduleItem>[];

  @override
  Future<void> upsertScheduleItem(String familyId, ScheduleItem item) async {}

  @override
  Future<void> deleteScheduleItem(String familyId, String itemId) async {}

  @override
  Future<List<Friend>> fetchFriends(String familyId) async =>
      const <Friend>[];

  @override
  Future<void> upsertFriend(String familyId, Friend friend) async {}

  @override
  Future<void> deleteFriend(String familyId, String friendId) async {}

  @override
  Future<List<GalleryItem>> fetchGalleryItems(String familyId) async =>
      const <GalleryItem>[];

  @override
  Future<void> upsertGalleryItem(String familyId, GalleryItem item) async {}

  @override
  Future<void> deleteGalleryItem(String familyId, String itemId) async {}

  @override
  Future<List<Chat>> fetchChats(String familyId) async => const <Chat>[];

  @override
  Future<void> upsertChat(String familyId, Chat chat) async {}

  @override
  Future<void> deleteChat(String familyId, String chatId) async {}

  @override
  Future<List<ChatMessage>> fetchChatMessages(
    String familyId,
    String chatId,
  ) async => const <ChatMessage>[];

  @override
  Future<void> upsertChatMessage(
    String familyId,
    String chatId,
    ChatMessage message,
  ) async {}

  @override
  Future<void> deleteChatMessages(String familyId, String chatId) async {}

  @override
  Future<List<Conversation>> fetchConversations(String familyId) async =>
      const <Conversation>[];

  @override
  Future<void> upsertConversation(
    String familyId,
    Conversation conversation,
  ) async {}

  @override
  Future<void> deleteConversation(String familyId, String conversationId) async {}

  @override
  Future<List<Message>> fetchCallMessages(
    String familyId,
    String conversationId,
  ) async => const <Message>[];

  @override
  Future<void> upsertCallMessage(
    String familyId,
    String conversationId,
    Message message,
  ) async {}

  @override
  Future<void> deleteCallMessages(String familyId, String conversationId) async {}
}

class _FakeStorageService extends StorageService {
  static const _emptyUpload =
      StorageUploadResult(downloadUrl: '', storagePath: '');

  @override
  Future<StorageUploadResult> uploadMemberAvatar({
    required String familyId,
    required File file,
  }) async => _emptyUpload;

  @override
  Future<StorageUploadResult> uploadGalleryItem({
    required String familyId,
    required File file,
  }) async => _emptyUpload;

  @override
  Future<StorageUploadResult> uploadChatAttachment({
    required String familyId,
    required String chatId,
    required File file,
  }) async => _emptyUpload;

  @override
  Future<void> deleteByPath(String storagePath) async {}

  @override
  Future<void> deleteByUrl(String url) async {}
}
