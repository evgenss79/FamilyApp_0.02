import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'ai_suggestions_screen.dart';
import 'calendar_feed_screen.dart';
import 'calendar_screen.dart';
import 'call_setup_screen.dart';
import 'chat_list_screen.dart';
import 'cloud_call_screen.dart';
import 'events_screen.dart';
import 'friends_screen.dart';
import 'gallery_screen.dart';
import 'members_screen.dart';
import 'schedule_screen.dart';
import 'scoreboard_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<_Feature> _features = [
    _Feature(
      titleKey: 'members',
      descriptionKey: 'membersDescription',
      icon: Icons.group,
      builder: (_) => const MembersScreen(),
    ),
    _Feature(
      titleKey: 'tasks',
      descriptionKey: 'tasksDescription',
      icon: Icons.checklist,
      builder: (_) => const TasksScreen(),
    ),
    _Feature(
      titleKey: 'events',
      descriptionKey: 'eventsDescription',
      icon: Icons.event,
      builder: (_) => const EventsScreen(),
    ),
    _Feature(
      titleKey: 'calendar',
      descriptionKey: 'calendarDescription',
      icon: Icons.calendar_today,
      builder: (_) => const CalendarScreen(),
    ),
    _Feature(
      titleKey: 'schedule',
      descriptionKey: 'scheduleDescription',
      icon: Icons.schedule,
      builder: (_) => const ScheduleScreen(),
    ),
    _Feature(
      titleKey: 'scoreboard',
      descriptionKey: 'scoreboardDescription',
      icon: Icons.leaderboard,
      builder: (_) => const ScoreboardScreen(),
    ),
    _Feature(
      titleKey: 'gallery',
      descriptionKey: 'galleryDescription',
      icon: Icons.photo_library,
      builder: (_) => const GalleryScreen(),
    ),
    _Feature(
      titleKey: 'friends',
      descriptionKey: 'friendsDescription',
      icon: Icons.people_alt,
      builder: (_) => const FriendsScreen(),
    ),
    _Feature(
      titleKey: 'chats',
      descriptionKey: 'chatsDescription',
      icon: Icons.chat_bubble_outline,
      builder: (_) => const ChatListScreen(),
    ),
    _Feature(
      titleKey: 'aiSuggestions',
      descriptionKey: 'aiSuggestionsDescription',
      icon: Icons.auto_awesome,
      builder: (_) => const AiSuggestionsScreen(),
    ),
    _Feature(
      titleKey: 'calendarFeed',
      descriptionKey: 'calendarFeedDescription',
      icon: Icons.rss_feed,
      builder: (_) => const CalendarFeedScreen(),
    ),
    _Feature(
      titleKey: 'startCall',
      descriptionKey: 'startCallDescription',
      icon: Icons.call,
      builder: (_) => const CallSetupScreen(),
    ),
    _Feature(
      titleKey: 'cloudCall',
      descriptionKey: 'cloudCallDescription',
      icon: Icons.cloud,
      builder: (_) => const CloudCallScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('homeHubTitle'))),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  context.tr('appTitle'),
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            for (final feature in _features)
              ListTile(
                leading: Icon(feature.icon),
                title: Text(context.tr(feature.titleKey)),
                subtitle: Text(context.tr(feature.descriptionKey)),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: feature.builder),
                  );
                },
              ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: _features.length,
        itemBuilder: (context, index) {
          final feature = _features[index];
          return _FeatureCard(feature: feature);
        },
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: feature.builder),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(feature.icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                context.tr(feature.titleKey),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(feature.descriptionKey),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final WidgetBuilder builder;

  const _Feature({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.builder,
  });
}
