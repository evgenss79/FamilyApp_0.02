import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/language_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageProvider = context.watch<LanguageProvider>();
    final features = _buildFeatures(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.t('homeHubTitle'))),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.indigo),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  l10n.t('drawerTitle'),
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(l10n.t('languageMenuTitle')),
              subtitle: Text(l10n.t('languageMenuSubtitle')),
              trailing: DropdownButtonHideUnderline(
                child: DropdownButton<Locale>(
                  value: languageProvider.locale,
                  onChanged: (locale) {
                    if (locale != null) {
                      context.read<LanguageProvider>().setLocale(locale);
                    }
                  },
                  items: [
                    for (final locale in AppLocalizations.supportedLocales)
                      DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(
                          l10n.languageName(locale.languageCode),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            for (final feature in features)
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
        itemCount: features.length,
        itemBuilder: (context, index) {
          final feature = features[index];
          return _FeatureCard(feature: feature);
        },
      ),
    );
  }

  List<_Feature> _buildFeatures(BuildContext context) {
    final l10n = context.l10n;
    return [
      _Feature(
        title: l10n.t('feature.members.title'),
        description: l10n.t('feature.members.description'),
        icon: Icons.group,
        builder: (_) => const MembersScreen(),
      ),
      _Feature(
        title: l10n.t('feature.tasks.title'),
        description: l10n.t('feature.tasks.description'),
        icon: Icons.checklist,
        builder: (_) => const TasksScreen(),
      ),
      _Feature(
        title: l10n.t('feature.events.title'),
        description: l10n.t('feature.events.description'),
        icon: Icons.event,
        builder: (_) => const EventsScreen(),
      ),
      _Feature(
        title: l10n.t('feature.calendar.title'),
        description: l10n.t('feature.calendar.description'),
        icon: Icons.calendar_today,
        builder: (_) => const CalendarScreen(),
      ),
      _Feature(
        title: l10n.t('feature.schedule.title'),
        description: l10n.t('feature.schedule.description'),
        icon: Icons.schedule,
        builder: (_) => const ScheduleScreen(),
      ),
      _Feature(
        title: l10n.t('feature.scoreboard.title'),
        description: l10n.t('feature.scoreboard.description'),
        icon: Icons.leaderboard,
        builder: (_) => const ScoreboardScreen(),
      ),
      _Feature(
        title: l10n.t('feature.gallery.title'),
        description: l10n.t('feature.gallery.description'),
        icon: Icons.photo_library,
        builder: (_) => const GalleryScreen(),
      ),
      _Feature(
        title: l10n.t('feature.friends.title'),
        description: l10n.t('feature.friends.description'),
        icon: Icons.people_alt,
        builder: (_) => const FriendsScreen(),
      ),
      _Feature(
        title: l10n.t('feature.chats.title'),
        description: l10n.t('feature.chats.description'),
        icon: Icons.chat_bubble_outline,
        builder: (_) => const ChatListScreen(),
      ),
      _Feature(
        title: l10n.t('feature.ai.title'),
        description: l10n.t('feature.ai.description'),
        icon: Icons.auto_awesome,
        builder: (_) => const AiSuggestionsScreen(),
      ),
      _Feature(
        title: l10n.t('feature.calendarFeed.title'),
        description: l10n.t('feature.calendarFeed.description'),
        icon: Icons.rss_feed,
        builder: (_) => const CalendarFeedScreen(),
      ),
      _Feature(
        title: l10n.t('feature.callSetup.title'),
        description: l10n.t('feature.callSetup.description'),
        icon: Icons.call,
        builder: (_) => const CallSetupScreen(),
      ),
      _Feature(
        title: l10n.t('feature.cloudCall.title'),
        description: l10n.t('feature.cloudCall.description'),
        icon: Icons.cloud,
        builder: (_) => const CloudCallScreen(),
      ),
    ];
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
