import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/network/dio_client.dart';
import '../api/models/calendar.dart';
import '../api/models/cutoff_record.dart';
import '../api/models/episode.dart';
import '../api/models/history.dart';
import '../api/models/quality_profile.dart';
import '../api/models/queue.dart';
import '../api/models/release.dart';
import '../api/models/root_folder.dart';
import '../api/models/series.dart';
import '../api/models/system_status.dart';
import '../api/models/tag.dart';
import '../api/sonarr_api.dart';
import '../models/sonarr_options.dart';

/// Persists the display mode (Grid/List) for Sonarr series.
final sonarrDisplayModeProvider =
    StateProvider.family<DisplayMode, int>((ref, instanceId) => DisplayMode.grid);

/// Search query for Sonarr series.
final sonarrSearchQueryProvider = StateProvider.family<String, int>((ref, instanceId) => '');

/// Current sort option for Sonarr series.
final sonarrSortOptionProvider = StateProvider.family<SonarrSortOption, int>(
    (ref, instanceId) => SonarrSortOption.alphabetical);

/// Current filter option for Sonarr series.
final sonarrFilterOptionProvider = StateProvider.family<SonarrFilterOption, int>(
    (ref, instanceId) => SonarrFilterOption.all);

/// Whether to sort in ascending order.
final sonarrSortAscendingProvider = StateProvider.family<bool, int>((ref, instanceId) => true);

/// Creates a [SonarrApi] scoped to a specific [Instance].
final sonarrApiProvider = Provider.family<SonarrApi, Instance>((ref, instance) {
  final dio = ref.watch(dioProvider(instance));
  return SonarrApi(dio);
});

/// Fetches all series from Sonarr for [instance].
final sonarrSeriesProvider = FutureProvider.autoDispose
    .family<List<SonarrSeries>, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getSeries();
});

/// Fetches episodes that don't meet the quality cutoff for [instance].
final sonarrCutoffUnmetProvider = FutureProvider.autoDispose
    .family<List<SonarrCutoffRecord>, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getCutoffUnmet();
});

/// Fetches upcoming episodes (Calendar) from Sonarr for [instance].
final sonarrCalendarProvider = FutureProvider.autoDispose
    .family<List<SonarrCalendar>, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 30));
  return api.getCalendar(start, end);
});

/// Fetches current download queue from Sonarr for [instance].
final sonarrQueueProvider =
    FutureProvider.autoDispose.family<SonarrQueue, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getQueue();
});

/// Fetches event history from Sonarr for [instance].
final sonarrHistoryProvider =
    FutureProvider.autoDispose.family<SonarrHistory, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getHistory();
});

/// Fetches quality profiles from Sonarr for [instance].
final sonarrQualityProfilesProvider = FutureProvider.autoDispose
    .family<List<SonarrQualityProfile>, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getQualityProfiles();
});

/// Fetches root folders from Sonarr for [instance].
final sonarrRootFoldersProvider = FutureProvider.autoDispose
    .family<List<SonarrRootFolder>, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getRootFolders();
});

/// Fetches system status from Sonarr for [instance].
final sonarrSystemStatusProvider = FutureProvider.autoDispose
    .family<SonarrSystemStatus, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getSystemStatus();
});

/// Fetches health check items from Sonarr for [instance].
final sonarrHealthProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getHealth();
});

/// Fetches disk space info from Sonarr for [instance].
final sonarrDiskSpaceProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getDiskSpace();
});

/// Fetches tags from Sonarr for [instance].
final sonarrTagsProvider = FutureProvider.autoDispose
    .family<List<SonarrTag>, Instance>((ref, instance) {
  final api = ref.watch(sonarrApiProvider(instance));
  return api.getTags();
});

/// Search query for the add-series lookup screen.
final sonarrLookupQueryProvider =
    StateProvider.family<String, int>((ref, instanceId) => '');

/// Performs a series lookup against Sonarr for [instance].
final sonarrLookupResultsProvider = FutureProvider.autoDispose
    .family<List<SonarrSeries>, Instance>((ref, instance) {
  final query = ref.watch(sonarrLookupQueryProvider(instance.id));
  if (query.trim().isEmpty) return Future.value([]);
  final api = ref.watch(sonarrApiProvider(instance));
  return api.lookupSeries(query);
});

/// Fetches episodes for a specific series season.
final sonarrEpisodesProvider = FutureProvider.autoDispose
    .family<List<SonarrEpisode>, ({Instance instance, int seriesId, int seasonNumber})>(
        (ref, args) {
  final api = ref.watch(sonarrApiProvider(args.instance));
  return api.getEpisodes(args.seriesId, args.seasonNumber);
});

/// Fetches releases for a specific series (optionally scoped to a season).
final sonarrReleasesProvider = FutureProvider.autoDispose
    .family<List<SonarrRelease>, ({Instance instance, int seriesId, int? seasonNumber, int? episodeId})>(
        (ref, args) {
  final api = ref.watch(sonarrApiProvider(args.instance));
  return api.getReleases(
    seriesId: args.seriesId,
    seasonNumber: args.seasonNumber,
    episodeId: args.episodeId,
  );
});

/// A provider that returns a filtered and sorted list of series.
final sonarrFilteredSeriesProvider = Provider.family<List<SonarrSeries>, Instance>((ref, instance) {
  final seriesAsync = ref.watch(sonarrSeriesProvider(instance));
  final query = ref.watch(sonarrSearchQueryProvider(instance.id)).toLowerCase();
  final sortOption = ref.watch(sonarrSortOptionProvider(instance.id));
  final filterOption = ref.watch(sonarrFilterOptionProvider(instance.id));
  final ascending = ref.watch(sonarrSortAscendingProvider(instance.id));

  return seriesAsync.maybeWhen(
    data: (series) {
      // 1. Filter
      var filtered = series.where((s) {
        // Search query
        if (query.isNotEmpty && !s.title.toLowerCase().contains(query)) {
          return false;
        }
        // Filter option
        switch (filterOption) {
          case SonarrFilterOption.all:
            return true;
          case SonarrFilterOption.monitored:
            return s.monitored;
          case SonarrFilterOption.unmonitored:
            return !s.monitored;
          case SonarrFilterOption.continuing:
            return s.status?.toLowerCase() == 'continuing';
          case SonarrFilterOption.ended:
            return s.status?.toLowerCase() == 'ended';
          case SonarrFilterOption.missing:
            final epCount = s.statistics?.episodeCount ?? 0;
            final fileCount = s.statistics?.episodeFileCount ?? 0;
            return epCount > 0 && epCount != fileCount;
        }
      }).toList();

      // 2. Sort
      filtered.sort((a, b) {
        int compare;
        switch (sortOption) {
          case SonarrSortOption.alphabetical:
            compare = (a.sortTitle ?? a.title)
                .toLowerCase()
                .compareTo((b.sortTitle ?? b.title).toLowerCase());
          case SonarrSortOption.dateAdded:
            compare = (a.added ?? DateTime(0)).compareTo(b.added ?? DateTime(0));
          case SonarrSortOption.episodes:
            compare = (a.statistics?.percentOfEpisodes ?? 0)
                .compareTo(b.statistics?.percentOfEpisodes ?? 0);
          case SonarrSortOption.network:
            compare = (a.network ?? '').compareTo(b.network ?? '');
          case SonarrSortOption.nextAiring:
            // Handle nulls by putting them at the end if ascending, or start if descending.
            if (a.nextAiring == null && b.nextAiring == null) {
              compare = 0;
            } else if (a.nextAiring == null) {
              compare = 1;
            } else if (b.nextAiring == null) {
              compare = -1;
            } else {
              compare = a.nextAiring!.compareTo(b.nextAiring!);
            }
          case SonarrSortOption.previousAiring:
            if (a.previousAiring == null && b.previousAiring == null) {
              compare = 0;
            } else if (a.previousAiring == null) {
              compare = 1;
            } else if (b.previousAiring == null) {
              compare = -1;
            } else {
              compare = a.previousAiring!.compareTo(b.previousAiring!);
            }
          case SonarrSortOption.qualityProfile:
            compare = (a.qualityProfileId ?? 0).compareTo(b.qualityProfileId ?? 0);
          case SonarrSortOption.size:
            compare = (a.statistics?.sizeOnDisk ?? 0)
                .compareTo(b.statistics?.sizeOnDisk ?? 0);
          case SonarrSortOption.type:
            compare = (a.seriesType ?? '').compareTo(b.seriesType ?? '');
        }
        return ascending ? compare : -compare;
      });

      return filtered;
    },
    orElse: () => [],
  );
});
