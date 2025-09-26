import '../models/family_member.dart';
import 'base_firestore_repository.dart';

class MembersRepository extends BaseFirestoreRepository<FamilyMember> {
  MembersRepository()
      : super(
          collectionName: 'members',
          fromMap: FamilyMember.fromMap,
          toMap: (FamilyMember member) => member.toMap(),
          idSelector: (FamilyMember member) => member.id,
          sorter: (FamilyMember a, FamilyMember b) {
            final DateTime aTime = a.updatedAt ?? a.createdAt ?? DateTime(1970);
            final DateTime bTime = b.updatedAt ?? b.createdAt ?? DateTime(1970);
            return bTime.compareTo(aTime);
          },
        );
}

