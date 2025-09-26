import '../models/friend.dart';
import 'base_firestore_repository.dart';

class FriendsRepository extends BaseFirestoreRepository<Friend> {
  FriendsRepository()
      : super(
          collectionName: 'friends',
          fromMap: Friend.fromMap,
          toMap: (Friend friend) => friend.toMap(),
          idSelector: (Friend friend) => friend.id,
          sorter: (Friend a, Friend b) => a.name.compareTo(b.name),
        );
}

