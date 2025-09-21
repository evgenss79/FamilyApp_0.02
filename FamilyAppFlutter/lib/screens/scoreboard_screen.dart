import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';
import '../models/family_member.dart';
import '../models/task.dart';

/// Displays a leaderboard of family members ordered by total points
/// earned from completed tasks.  Members with more points appear
/// higher in the list.  When two members have the same number of
/// points they are sorted alphabetically by name.
class ScoreboardScreen extends StatelessWidget {
  const ScoreboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoreboard'),
      ),
      body: Consumer<FamilyData>(
        builder: (context, data, _) {
          // Create a copy to sort without mutating the original list.
          final List<FamilyMember> members = List<FamilyMember>.from(data.members);
          // Sort by points descending, then by name ascending.
          members.sort((a, b) {
            final int pointsA = _calculatePointsForMember(a, data.tasks);
            final int pointsB = _calculatePointsForMember(b, data.tasks);
            if (pointsA == pointsB) {
              return (a.name ?? '').compareTo(b.name ?? '');
            }
            return pointsB.compareTo(pointsA);
          });
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final int points = _calculatePointsForMember(member, data.tasks);
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text(member.name ?? ''),
                subtitle: Text(member.relationship ?? ''),
                trailing: Text(
                  '$points pts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Calculates the sum of points for all tasks assigned to [member]
  /// that have been marked as completed.
  int _calculatePointsForMember(FamilyMember member, List<Task> tasks) {
    var total = 0;
    for (final task in tasks) {
      if (task.assignedMemberId == member.id && task.status == TaskStatus.completed) {
        total += task.points ?? 0;
      }
    }
    return total;
  }
}