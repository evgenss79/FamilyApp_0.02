import '../models/task.dart';
import 'base_firestore_repository.dart';

class TasksRepository extends BaseFirestoreRepository<Task> {
  TasksRepository()
      : super(
          collectionName: 'tasks',
          fromMap: Task.fromMap,
          toMap: (Task task) => task.toMap(),
          idSelector: (Task task) => task.id,
          sorter: (Task a, Task b) {
            final DateTime aDue = a.dueDate ?? DateTime(1970);
            final DateTime bDue = b.dueDate ?? DateTime(1970);
            return aDue.compareTo(bDue);
          },
        );
}

