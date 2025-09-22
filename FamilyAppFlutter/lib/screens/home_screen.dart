import 'package:flutter/material.dart';

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

  static final List<_Feature> _features = [
    _Feature(
      title: 'Members',
      description: 'Manage family members and view details',
      icon: Icons.group,
      builder: (_) => const MembersScreen(),
    ),
    _Feature(
      title: 'Tasks',
      description: 'Assign chores and track status',
      icon: Icons.checklist,
      builder: (_) => const TasksScreen(),
    ),
    _Feature(
      title: 'Events',
      description: 'Plan family events and gatherings',
      icon: Icons.event,
      builder: (_) => const EventsScreen(),
    ),
    _Feature(
      title: 'Calendar',
      description: 'Overview of upcoming events and tasks',
      icon: Icons.calendar_today,
      builder: (_) => const CalendarScreen(),
    ),
    _Feature(
      title: 'Schedule',
      description: 'Personal schedule and agenda',
      icon: Icons.schedule,
      builder: (_) => const ScheduleScreen(),
    ),
    _Feature(
      title: 'Scoreboard',
      description: 'Gamify tasks with points',
      icon: Icons.leaderboard,
      builder: (_) => const ScoreboardScreen(),
    ),
    _Feature(
      title: 'Gallery',
      description: 'Family photos and memories',
      icon: Icons.photo_library,
      builder: (_) => const GalleryScreen(),
    ),
    _Feature(
      title: 'Friends',
      description: 'Keep track of friends of the family',
      icon: Icons.people_alt,
      builder: (_) => const FriendsScreen(),
    ),
    _Feature(
      title: 'Chats',
      description: 'Group and private conversations',
      icon: Icons.chat_bubble_outline,
      builder: (_) => const ChatListScreen(),
    ),
    _Feature(
      title: 'AI suggestions',
      description: 'Get ideas from the assistant',
      icon: Icons.auto_awesome,
      builder: (_) => const AiSuggestionsScreen(),
    ),
    _Feature(
      title: 'Calendar feed',
      description: 'Latest updates from the calendar',
      icon: Icons.rss_feed,
      builder: (_) => const CalendarFeedScreen(),
    ),
    _Feature(
      title: 'Start a call',
      description: 'Create an audio or video call',
      icon: Icons.call,
      builder: (_) => const CallSetupScreen(),
    ),
    _Feature(
      title: 'Cloud call',
      description: 'Join the cloud call lobby',
      icon: Icons.cloud,
      builder: (_) => const CloudCallScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family App Hub')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Family App',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            for (final feature in _features)
              ListTile(
                leading: Icon(feature.icon),
                title: Text(feature.title),
                subtitle: Text(feature.description),
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
                feature.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                feature.description,
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
  final String title;
  final String description;
  final IconData icon;
  final WidgetBuilder builder;

  const _Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.builder,
  });
}
