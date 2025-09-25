import '../models/conversation.dart';
import 'base_firestore_repository.dart';

class CallsRepository extends BaseFirestoreRepository<Conversation> {
  CallsRepository()
      : super(
          collectionName: 'calls',
          fromMap: Conversation.fromMap,
          toMap: (Conversation call) => call.toMap(),
          idSelector: (Conversation call) => call.id,
          sorter: (Conversation a, Conversation b) =>
              (b.updatedAt ?? b.createdAt)
                  .compareTo(a.updatedAt ?? a.createdAt),
        );
}

