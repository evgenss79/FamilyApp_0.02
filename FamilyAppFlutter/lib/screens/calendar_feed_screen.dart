import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// Placeholder screen for a calendar feed.  This simplified view
/// contains no data and simply informs the user that no feed is
/// available.  Expand this screen to show recent events or
/// notifications as needed.
class CalendarFeedScreen extends StatelessWidget {
  const CalendarFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('calendarFeed'))),
      body: Center(child: Text(context.tr('noCalendarFeedLabel'))),
    );
  }
}
