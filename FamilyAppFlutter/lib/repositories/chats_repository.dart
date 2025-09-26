import '../models/chat.dart';
import 'base_firestore_repository.dart';

class ChatsRepository extends BaseFirestoreRepository<Chat> {
  ChatsRepository()
      : super(
          collectionName: 'chats',
          fromMap: Chat.fromMap,
          toMap: (Chat chat) => chat.toMap(),
          idSelector: (Chat chat) => chat.id,
          sorter: (Chat a, Chat b) => b.updatedAt.compareTo(a.updatedAt),
        );
}

