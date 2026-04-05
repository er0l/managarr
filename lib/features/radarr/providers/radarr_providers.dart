import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/network/dio_client.dart';
import '../api/models/history.dart';
import '../api/models/movie.dart';
import '../api/models/movie_file.dart';
import '../api/models/quality_profile.dart';
import '../api/models/queue.dart';
import '../api/models/release.dart';
import '../api/models/root_folder.dart';
import '../api/models/system_status.dart';
import '../api/models/tag.dart';
import '../api/radarr_api.dart';
import '../models/radarr_options.dart';

/// Persists the display mode (Grid/List) for Radarr movies.
final radarrDisplayModeProvider =
    StateProvider.family<DisplayMode, int>((ref, instanceId) => DisplayMode.grid);

/// Search query for Radarr movies.
final radarrSearchQueryProvider = StateProvider.family<String, int>((ref, instanceId) => '');

/// Current sort option for Radarr movies.
final radarrSortOptionProvider = StateProvider.family<RadarrSortOption, int>(
    (ref, instanceId) => RadarrSortOption.alphabetical);

/// Current filter option for Radarr movies.
final radarrFilterOptionProvider = StateProvider.family<RadarrFilterOption, int>(
    (ref, instanceId) => RadarrFilterOption.all);

/// Whether to sort in ascending order.
final radarrSortAscendingProvider = StateProvider.family<bool, int>((ref, instanceId) => true);

/// Creates a [RadarrApi] scoped to a specific [Instance].
final radarrApiProvider = Provider.family<RadarrApi, Instance>((ref, instance) {
  final dio = ref.watch(dioProvider(instance));
  return RadarrApi(dio);
});

/// Fetches all movies from Radarr for [instance].
final radarrMoviesProvider = FutureProvider.autoDispose
    .family<List<RadarrMovie>, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getMovies();
});

/// Fetches movies that don't meet the quality cutoff for [instance].
final radarrCutoffUnmetProvider = FutureProvider.autoDispose
    .family<List<RadarrMovie>, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getCutoffUnmet();
});

/// Fetches upcoming releases (Calendar) from Radarr for [instance].
final radarrCalendarProvider = FutureProvider.autoDispose
    .family<List<RadarrMovie>, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 90)); // 3 months lookahead
  return api.getCalendar(start, end);
});

/// Fetches current download queue from Radarr for [instance].
final radarrQueueProvider =
    FutureProvider.autoDispose.family<RadarrQueue, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getQueue();
});

/// Fetches event history from Radarr for [instance].
final radarrHistoryProvider =
    FutureProvider.autoDispose.family<RadarrHistory, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getHistory();
});

/// Fetches quality profiles from Radarr for [instance].
final radarrQualityProfilesProvider = FutureProvider.autoDispose
    .family<List<RadarrQualityProfile>, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getQualityProfiles();
});

/// Fetches system status from Radarr for [instance].
final radarrSystemStatusProvider = FutureProvider.autoDispose
    .family<RadarrSystemStatus, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getSystemStatus();
});

/// Fetches root folders from Radarr for [instance].
final radarrRootFoldersProvider = FutureProvider.autoDispose
    .family<List<RadarrRootFolder>, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getRootFolders();
});

/// Search query for the add-movie lookup screen.
final radarrLookupQueryProvider =
    StateProvider.family<String, int>((ref, instanceId) => '');

/// Performs a movie lookup against Radarr for [instance].
/// Only triggers when the lookup query is non-empty.
final radarrLookupResultsProvider = FutureProvider.autoDispose
    .family<List<RadarrMovie>, Instance>((ref, instance) {
  final query = ref.watch(radarrLookupQueryProvider(instance.id));
  if (query.trim().isEmpty) return Future.value([]);
  final api = ref.watch(radarrApiProvider(instance));
  return api.lookupMovie(query);
});

/// Fetches health check items from Radarr for [instance].
final radarrHealthProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getHealth();
});

/// Fetches disk space info from Radarr for [instance].
final radarrDiskSpaceProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getDiskSpace();
});

/// Fetches tags from Radarr for [instance].
final radarrTagsProvider = FutureProvider.autoDispose
    .family<List<RadarrTag>, Instance>((ref, instance) {
  final api = ref.watch(radarrApiProvider(instance));
  return api.getTags();
});

/// Fetches movie files for a specific movie.
/// Key is a record of (Instance, movieId).
final radarrMovieFilesProvider = FutureProvider.autoDispose
    .family<List<RadarrMovieFile>, ({Instance instance, int movieId})>(
        (ref, args) {
  final api = ref.watch(radarrApiProvider(args.instance));
  return api.getMovieFiles(args.movieId);
});

/// Fetches history for a specific movie.
final radarrMovieHistoryProvider = FutureProvider.autoDispose
    .family<RadarrHistory, ({Instance instance, int movieId})>((ref, args) {
  final api = ref.watch(radarrApiProvider(args.instance));
  return api.getMovieHistory(args.movieId);
});

/// Fetches releases for a specific movie.
final radarrReleasesProvider = FutureProvider.autoDispose
    .family<List<RadarrRelease>, ({Instance instance, int movieId})>(
        (ref, args) {
  final api = ref.watch(radarrApiProvider(args.instance));
  return api.getReleases(args.movieId);
});

/// A provider that returns a filtered and sorted list of movies.
final radarrFilteredMoviesProvider = Provider.family<List<RadarrMovie>, Instance>((ref, instance) {
  final moviesAsync = ref.watch(radarrMoviesProvider(instance));
  final query = ref.watch(radarrSearchQueryProvider(instance.id)).toLowerCase();
  final sortOption = ref.watch(radarrSortOptionProvider(instance.id));
  final filterOption = ref.watch(radarrFilterOptionProvider(instance.id));
  final ascending = ref.watch(radarrSortAscendingProvider(instance.id));

  return moviesAsync.maybeWhen(
    data: (movies) {
      // 1. Filter
      var filtered = movies.where((m) {
        // Search query
        if (query.isNotEmpty && !m.title.toLowerCase().contains(query)) {
          return false;
        }
        // Filter option
        switch (filterOption) {
          case RadarrFilterOption.all:
            return true;
          case RadarrFilterOption.monitored:
            return m.monitored;
          case RadarrFilterOption.unmonitored:
            return !m.monitored;
          case RadarrFilterOption.missing:
            return !m.hasFile && m.monitored;
          case RadarrFilterOption.wanted:
            return !m.hasFile && m.monitored;
          case RadarrFilterOption.cutoffUnmet:
            // This requires more fields from the API which we might not have yet (cutoffNotMet)
            // For now, treat it as all monitored
            return m.monitored;
        }
      }).toList();

      // 2. Sort
      filtered.sort((a, b) {
        int compare;
        switch (sortOption) {
          case RadarrSortOption.alphabetical:
            compare = (a.sortTitle ?? a.title)
                .toLowerCase()
                .compareTo((b.sortTitle ?? b.title).toLowerCase());
          case RadarrSortOption.dateAdded:
            compare = (a.added ?? DateTime(0)).compareTo(b.added ?? DateTime(0));
          case RadarrSortOption.year:
            compare = a.year.compareTo(b.year);
          case RadarrSortOption.size:
            compare = (a.sizeOnDisk ?? 0).compareTo(b.sizeOnDisk ?? 0);
          case RadarrSortOption.runtime:
            compare = (a.runtime ?? 0).compareTo(b.runtime ?? 0);
          case RadarrSortOption.studio:
            compare = (a.studio ?? '').compareTo(b.studio ?? '');
          case RadarrSortOption.qualityProfile:
            compare = (a.qualityProfileId ?? 0).compareTo(b.qualityProfileId ?? 0);
          case RadarrSortOption.inCinemas:
            compare = (a.inCinemas ?? DateTime(0)).compareTo(b.inCinemas ?? DateTime(0));
          case RadarrSortOption.physicalRelease:
            compare = (a.physicalRelease ?? DateTime(0)).compareTo(b.physicalRelease ?? DateTime(0));
          case RadarrSortOption.digitalRelease:
            compare = (a.digitalRelease ?? DateTime(0)).compareTo(b.digitalRelease ?? DateTime(0));
        }
        return ascending ? compare : -compare;
      });

      return filtered;
    },
    orElse: () => [],
  );
});
