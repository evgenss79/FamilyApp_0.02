import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../services/remote_config_service.dart';
import '../storage/local_store.dart';
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
import 'profile_screen.dart';
import 'schedule_screen.dart';
import 'scoreboard_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static final List<HomeFeature> features = [
    HomeFeature(
      titleKey: 'members',
      descriptionKey: 'membersDescription',
      icon: Icons.group,
      builder: (_) => const MembersScreen(),
    ),
    HomeFeature(
      titleKey: 'tasks',
      descriptionKey: 'tasksDescription',
      icon: Icons.checklist,
      builder: (_) => const TasksScreen(),
    ),
    HomeFeature(
      titleKey: 'events',
      descriptionKey: 'eventsDescription',
      icon: Icons.event,
      builder: (_) => const EventsScreen(),
    ),
    HomeFeature(
      titleKey: 'calendar',
      descriptionKey: 'calendarDescription',
      icon: Icons.calendar_today,
      builder: (_) => const CalendarScreen(),
    ),
    HomeFeature(
      titleKey: 'schedule',
      descriptionKey: 'scheduleDescription',
      icon: Icons.schedule,
      builder: (_) => const ScheduleScreen(),
    ),
    HomeFeature(
      titleKey: 'scoreboard',
      descriptionKey: 'scoreboardDescription',
      icon: Icons.leaderboard,
      builder: (_) => const ScoreboardScreen(),
    ),
    HomeFeature(
      titleKey: 'gallery',
      descriptionKey: 'galleryDescription',
      icon: Icons.photo_library,
      builder: (_) => const GalleryScreen(),
    ),
    HomeFeature(
      titleKey: 'friends',
      descriptionKey: 'friendsDescription',
      icon: Icons.people_alt,
      builder: (_) => const FriendsScreen(),
    ),
    HomeFeature(
      titleKey: 'chats',
      descriptionKey: 'chatsDescription',
      icon: Icons.chat_bubble_outline,
      builder: (_) => const ChatListScreen(),
    ),
    HomeFeature(
      titleKey: 'aiSuggestions',
      descriptionKey: 'aiSuggestionsDescription',
      icon: Icons.auto_awesome,
      builder: (_) => const AiSuggestionsScreen(),
    ),
    HomeFeature(
      titleKey: 'calendarFeed',
      descriptionKey: 'calendarFeedDescription',
      icon: Icons.rss_feed,
      builder: (_) => const CalendarFeedScreen(),
    ),
    HomeFeature(
      titleKey: 'startCall',
      descriptionKey: 'startCallDescription',
      icon: Icons.call,
      builder: (_) => const CallSetupScreen(),
    ),
    HomeFeature(
      titleKey: 'cloudCall',
      descriptionKey: 'cloudCallDescription',
      icon: Icons.cloud,
      builder: (_) => const CloudCallScreen(),
    ),
  ];

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late bool _onboardingDismissed;

  @override
  void initState() {
    super.initState();
    _onboardingDismissed = LocalStore.isOnboardingTipsDismissed();
  }

  Future<void> _dismissOnboardingTips() async {
    await LocalStore.setOnboardingTipsDismissed(true);
    if (!mounted) {
      return;
    }
    setState(() {
      _onboardingDismissed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final RemoteConfigService remoteConfig =
        context.watch<RemoteConfigService>();
    final AuthProvider auth = context.watch<AuthProvider>();
    final List<HomeFeature> features =
        HomeScreen.features.where((HomeFeature feature) {
      if (!remoteConfig.aiSuggestionsEnabled &&
          feature.titleKey == 'aiSuggestions') {
        return false;
      }
      if (!remoteConfig.webRtcEnabled &&
          (feature.titleKey == 'startCall' ||
              feature.titleKey == 'cloudCall')) {
        return false;
      }
      return true;
    }).toList();
    final bool showOnboardingBanner =
        remoteConfig.onboardingTipsEnabled && !_onboardingDismissed;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('homeHubTitle')),
        actions: [
          if (auth.currentMember != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  auth.currentMember!.name ?? context.tr('profileMenuTitle'),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
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
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(context.tr('profileMenuTitle')),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.tr('languageMenuTitle')),
              subtitle: Text(context.tr('languageMenuSubtitle')),
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
                          context.loc.languageName(locale.languageCode),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(context.tr('signOutButton')),
              onTap: () async {
                Navigator.of(context).pop();
                await context.read<AuthProvider>().signOut();
              },
            ),
            const Divider(height: 1),
            for (final feature in features)
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
      body: Column(
        children: [
          if (showOnboardingBanner)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: _OnboardingBanner(onDismiss: _dismissOnboardingTips),
            ),
          Expanded(
            child: GridView.builder(
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
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final HomeFeature feature;

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

class HomeFeature {
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final WidgetBuilder builder;

  const HomeFeature({
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.builder,
  });
}

class _OnboardingBanner extends StatelessWidget {
  const _OnboardingBanner({required this.onDismiss});

  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.tips_and_updates,
                    color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('onboardingTipsTitle'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr('onboardingTipsMessage'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.tr('onboardingDismissTooltip'),
                  onPressed: () {
                    onDismiss();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _OnboardingTag(labelKey: 'aiSuggestions'),
                _OnboardingTag(labelKey: 'chats'),
                _OnboardingTag(labelKey: 'startCall'),
                _OnboardingTag(labelKey: 'tasks'),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  onDismiss();
                },
                icon: const Icon(Icons.check_circle_outline),
                label: Text(context.tr('onboardingDismissAction')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingTag extends StatelessWidget {
  const _OnboardingTag({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.play_arrow, size: 16),
      label: Text(context.tr(labelKey)),
    );
  }
}
