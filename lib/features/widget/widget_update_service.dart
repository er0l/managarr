import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../calendar/providers/calendar_providers.dart';

/// Serialises [CalendarEntry] list to SharedPreferences and triggers an
/// Android home-screen widget refresh.
class WidgetUpdateService {
  static const _dataKey = 'widget_upcoming_releases';
  static const _androidWidgetName = 'UpcomingWidgetProvider';

  static Future<void> updateFromEntries(List<CalendarEntry> entries) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fmt = DateFormat('MMM d');

    final items = entries
        .where((e) => !e.date.isBefore(today))
        .take(25)
        .map((e) {
          final isMovie = e.type == CalendarEntryType.movie;
          final itemId = isMovie ? e.movie?.id : e.series?.id;
          final route = itemId != null
              ? isMovie
                  ? '/radarr/${e.instance.id}/movie/$itemId'
                  : '/sonarr/${e.instance.id}/series/$itemId'
              : isMovie
                  ? '/radarr/${e.instance.id}'
                  : '/sonarr/${e.instance.id}';
          return {
            'title': e.title,
            'subtitle': e.subtitle ?? '',
            'date': fmt.format(e.date),
            'type': isMovie ? 'movie' : 'tv',
            'route': route,
          };
        })
        .toList();

    await HomeWidget.saveWidgetData<String>(_dataKey, jsonEncode(items));
    await HomeWidget.updateWidget(androidName: _androidWidgetName);
  }
}
