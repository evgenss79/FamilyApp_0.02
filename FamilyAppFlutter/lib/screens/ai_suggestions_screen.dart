import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/family_data.dart';
import '../services/ai_suggestions_service.dart';

/// Screen displaying AI-powered gift and activity suggestions.
///
/// This screen uses [AISuggestionsService] to generate lists of gift ideas
/// for each family member and shared activities for the whole family.
class AISuggestionsScreen extends StatelessWidget {
  const AISuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final familyData = context.watch<FamilyDataV001>();
    final aiService = AISuggestionsService();
    final members = familyData.members;
    final activities = aiService.suggestActivities(members);
    return Scaffold(
      appBar: AppBar(title: const Text('AI‑предложения')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Идеи подарков',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final member in members) ...[
            Text(
              member.name,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            _buildGiftSuggestions(aiService.suggestGifts(member)),
            const SizedBox(height: 12),
          ],
          const Divider(),
          const Text(
            'Совместные занятия',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildActivitySuggestions(activities),
        ],
      ),
    );
  }

  Widget _buildGiftSuggestions(List<String> suggestions) {
    if (suggestions.isEmpty) {
      return const Text('Нет идей');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions.map((s) => Text('• $s')).toList(),
    );
  }

  Widget _buildActivitySuggestions(List<String> suggestions) {
    if (suggestions.isEmpty) {
      return const Text('Нет идей');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: suggestions.map((s) => Text('• $s')).toList(),
    );
  }
}
