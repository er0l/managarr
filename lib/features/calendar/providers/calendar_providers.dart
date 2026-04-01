import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/radarr/api/models/movie.dart';
import '../../../features/radarr/providers/radarr_providers.dart';
import '../../../features/settings/providers/instances_provider.dart';
import '../../../features/sonarr/api/models/calendar.dart';
import '../../../features/sonarr/api/models/series.dart';
import '../../../features/sonarr/providers/sonarr_providers.dart';

enum CalendarEntryType { movie, episode }

class CalendarEntry {
  const CalendarEntry({
    required this.date,
    required this.title,
    this.subtitle,
    this.posterUrl,
    required this.instanceName,
    required this.type,
    required this.instance,
    this.movie,
    this.series,
    this.hasFile = false,
    this.qualityName,
  });

  final DateTime date; // normalized to midnight local
  final String title;
  final String? subtitle;
  final String? posterUrl;
  final String instanceName;
  final CalendarEntryType type;

  /// The service instance this entry belongs to — used for detail navigation.
  final Instance instance;

  /// Set for [CalendarEntryType.movie] entries.
  final RadarrMovie? movie;

  /// Set for [CalendarEntryType.episode] entries.
  final SonarrSeries? series;

  /// Whether the file has been downloaded.
  final bool hasFile;

  /// Quality name of the downloaded file (null if not downloaded).
  final String? qualityName;

  factory CalendarEntry.fromMovie(
      RadarrMovie m, Instance instance, DateTime date) {
    return CalendarEntry(
      date: date,
      title: m.title,
      subtitle: m.status,
      posterUrl: m.posterUrl,
      instanceName: instance.name,
      type: CalendarEntryType.movie,
      instance: instance,
      movie: m,
      hasFile: m.hasFile,
      qualityName: m.qualityName,
    );
  }

  factory CalendarEntry.fromEpisode(SonarrCalendar ep, Instance instance) {
    // Prefer the plain airDate string ("YYYY-MM-DD") which Sonarr already
    // expresses in the show's local broadcast date.  Using airDateUtc.toLocal()
    // shifts late-UTC-evening airings into the *next* day for UTC+ timezones,
    // causing calendar grid cells to show no episode dots.
    DateTime date;
    if (ep.airDate != null && ep.airDate!.isNotEmpty) {
      final parts = ep.airDate!.split('-');
      date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } else {
      final raw = ep.airDateUtc!.toLocal();
      date = DateTime(raw.year, raw.month, raw.day);
    }
    final sn = ep.seasonNumber;
    final en = ep.episodeNumber;
    final epNum = (sn != null && en != null)
        ? 'S${sn.toString().padLeft(2, '0')}E${en.toString().padLeft(2, '0')}'
        : null;
    return CalendarEntry(
      date: date,
      title: ep.series?.title ?? 'Unknown',
      subtitle: epNum != null ? '$epNum · ${ep.title ?? ''}' : ep.title,
      posterUrl: ep.series?.posterUrl,
      instanceName: instance.name,
      type: CalendarEntryType.episode,
      instance: instance,
      series: ep.series,
      hasFile: ep.hasFile ?? false,
      qualityName: ep.qualityName,
    );
  }

  Color get typeColor =>
      type == CalendarEntryType.movie ? AppColors.orangeAccent : AppColors.tealPrimary;
}

/// Persists whether the Calendar tab shows the month-grid (true) or list (false).
final calendarViewModeProvider = StateProvider<bool>((ref) => false);

final unifiedCalendarProvider =
    FutureProvider.autoDispose<List<CalendarEntry>>((ref) async {
  final grouped = ref.watch(instancesByServiceProvider);
  final radarrInstances = grouped[ServiceType.radarr] ?? [];
  final sonarrInstances = grouped[ServiceType.sonarr] ?? [];

  final entries = <CalendarEntry>[];

  await Future.wait([
    ...radarrInstances.map((instance) async {
      try {
        final movies =
            await ref.watch(radarrCalendarProvider(instance).future);
        for (final movie in movies) {
          final raw =
              movie.digitalRelease ?? movie.physicalRelease ?? movie.inCinemas;
          if (raw != null) {
            final date = DateTime(raw.year, raw.month, raw.day);
            entries.add(CalendarEntry.fromMovie(movie, instance, date));
          }
        }
      } catch (_) {}
    }),
    ...sonarrInstances.map((instance) async {
      try {
        final eps = await ref.watch(sonarrCalendarProvider(instance).future);
        for (final ep in eps) {
          if (ep.airDate != null || ep.airDateUtc != null) {
            entries.add(CalendarEntry.fromEpisode(ep, instance));
          }
        }
      } catch (_) {}
    }),
  ]);

  entries.sort((a, b) => a.date.compareTo(b.date));
  return entries;
});
