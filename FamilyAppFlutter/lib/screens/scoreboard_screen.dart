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
          final Map<String, int> pointsByMember = {
            for (final member in members)
              member.id: _calculatePointsForMember(member, data.tasks),
          };

          // Sort by points descending, then by name ascending.
          members.sort((a, b) {
            final int pointsA = pointsByMember[a.id] ?? 0;
            final int pointsB = pointsByMember[b.id] ?? 0;
            if (pointsA == pointsB) {
              return (a.name ?? '').compareTo(b.name ?? '');
            }
            return pointsB.compareTo(pointsA);
          });
          return ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              final int points = pointsByMember[member.id] ?? 0;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  child: Text('${index + 1}'),
                ),
                title: Text(member.name?.isNotEmpty == true ? member.name! : 'Unnamed'),
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
      if (task.assigneeId == member.id && task.status == TaskStatus.done) {
        total += task.points ?? 0;
      }
    }
    return total;
  }
}