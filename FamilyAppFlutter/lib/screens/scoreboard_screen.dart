import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/family_data.dart';


/// Displays a leaderboard of family members ordered by total points earned.
/// Points are accumulated from completed tasks assigned to each member.
class ScoreboardScreenV001 extends StatelessWidget {
  const ScoreboardScreenV001({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scoreboard'),
      ),
      body: Consumer<FamilyDataV001>(
        builder: (context, data, _) {
          // Make a copy of members so sorting does not affect original order.
          final List<FamilyMember> members = List<FamilyMember>.from(data.members);
          // Compute points for each member and sort descending by points.
          members.sort((a, b) {
            final int pointsA = _calculatePointsForMember(a, data.tasks);
            final int pointsB = _calculatePointsForMember(b, data.tasks);
            // If equal points, preserve alphabetical order by name.
            if (pointsA == pointsB) {
              return a.name.compareTo(b.name);
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
                title: Text(member.name),
                subtitle: Text(member.relationship),
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

  /// Helper to calculate total earned points from completed tasks assigned to [member].
  int _calculatePointsForMember(FamilyMember member, List<Task> tasks) {
    return tasks
        .where((task) =>
            task.assignedMemberId == member.id &&
            task.status.toLowerCase() == 'completed')
        .fold<int>(0, (sum, task) => sum + task.points);
  }
}
