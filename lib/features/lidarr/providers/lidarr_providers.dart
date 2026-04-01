import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/network/dio_client.dart';
import '../api/lidarr_api.dart';
import '../api/models/artist.dart';
import '../api/models/album.dart';
import '../api/models/history.dart';
import '../api/models/metadata_profile.dart';
import '../api/models/quality_profile.dart';
import '../api/models/queue.dart';
import '../api/models/release.dart';
import '../api/models/root_folder.dart';
import '../api/models/tag.dart';
import '../api/models/track.dart';
import '../models/lidarr_options.dart';

/// Persists the display mode (Grid/List) for Lidarr artists.
final lidarrDisplayModeProvider =
    StateProvider.family<DisplayMode, int>((ref, instanceId) => DisplayMode.grid);

/// Search query for Lidarr artists.
final lidarrSearchQueryProvider = StateProvider.family<String, int>((ref, instanceId) => '');

/// Current sort option for Lidarr artists.
final lidarrSortOptionProvider = StateProvider.family<LidarrSortOption, int>(
    (ref, instanceId) => LidarrSortOption.alphabetical);

/// Current filter option for Lidarr artists.
final lidarrFilterOptionProvider = StateProvider.family<LidarrFilterOption, int>(
    (ref, instanceId) => LidarrFilterOption.all);

/// Whether to sort in ascending order.
final lidarrSortAscendingProvider = StateProvider.family<bool, int>((ref, instanceId) => true);

/// Creates a [LidarrApi] scoped to a specific [Instance].
final lidarrApiProvider = Provider.family<LidarrApi, Instance>((ref, instance) {
  final dio = ref.watch(dioProvider(instance));
  return LidarrApi(dio);
});

final lidarrArtistsProvider = FutureProvider.autoDispose
    .family<List<LidarrArtist>, Instance>((ref, instance) async {
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getArtists();
});

final lidarrAlbumsProvider = FutureProvider.autoDispose
    .family<List<LidarrAlbum>, (Instance, int)>((ref, arg) async {
  final (instance, artistId) = arg;
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getAlbums(artistId);
});

final lidarrTracksProvider = FutureProvider.autoDispose
    .family<List<LidarrTrack>, (Instance, int)>((ref, arg) async {
  final (instance, albumId) = arg;
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getTracks(albumId);
});

final lidarrQueueProvider = FutureProvider.autoDispose
    .family<LidarrQueue, Instance>((ref, instance) async {
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getQueue();
});

final lidarrHistoryProvider = FutureProvider.autoDispose
    .family<LidarrHistory, Instance>((ref, instance) async {
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getHistory();
});

final lidarrQualityProfilesProvider = FutureProvider.autoDispose
    .family<List<LidarrQualityProfile>, Instance>((ref, instance) async {
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getQualityProfiles();
});

final lidarrMetadataProfilesProvider = FutureProvider.autoDispose
    .family<List<LidarrMetadataProfile>, Instance>((ref, instance) async {
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getMetadataProfiles();
});

final lidarrRootFoldersProvider = FutureProvider.autoDispose
    .family<List<LidarrRootFolder>, Instance>((ref, instance) async {
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getRootFolders();
});

final lidarrTagsProvider = FutureProvider.autoDispose
    .family<List<LidarrTag>, Instance>((ref, instance) async {
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getTags();
});

/// Search query for the add-artist lookup screen.
final lidarrLookupQueryProvider =
    StateProvider.family<String, int>((ref, instanceId) => '');

/// Performs an artist lookup against Lidarr for [instance].
final lidarrLookupResultsProvider = FutureProvider.autoDispose
    .family<List<LidarrArtist>, Instance>((ref, instance) {
  final query = ref.watch(lidarrLookupQueryProvider(instance.id));
  if (query.trim().isEmpty) return Future.value([]);
  final api = ref.watch(lidarrApiProvider(instance));
  return api.lookupArtist(query);
});

/// Fetches releases for a specific album.
final lidarrAlbumReleasesProvider = FutureProvider.autoDispose
    .family<List<LidarrRelease>, ({Instance instance, int albumId})>(
        (ref, args) {
  final api = ref.watch(lidarrApiProvider(args.instance));
  return api.getAlbumReleases(args.albumId);
});

/// Fetches wanted/missing albums from Lidarr.
final lidarrWantedMissingProvider = FutureProvider.autoDispose
    .family<List<LidarrAlbum>, Instance>((ref, instance) async {
  final api = ref.watch(lidarrApiProvider(instance));
  return api.getWantedMissing();
});

final lidarrFilteredArtistsProvider =
    Provider.family<List<LidarrArtist>, Instance>((ref, instance) {
  final artistsAsync = ref.watch(lidarrArtistsProvider(instance));
  final query = ref.watch(lidarrSearchQueryProvider(instance.id)).toLowerCase();
  final sortOption = ref.watch(lidarrSortOptionProvider(instance.id));
  final filterOption = ref.watch(lidarrFilterOptionProvider(instance.id));
  final ascending = ref.watch(lidarrSortAscendingProvider(instance.id));

  return artistsAsync.maybeWhen(
    data: (artists) {
      var filtered = artists.where((a) {
        if (query.isNotEmpty && !a.artistName.toLowerCase().contains(query)) {
          return false;
        }
        switch (filterOption) {
          case LidarrFilterOption.all:
            return true;
          case LidarrFilterOption.monitored:
            return a.monitored;
          case LidarrFilterOption.unmonitored:
            return !a.monitored;
          case LidarrFilterOption.missing:
            final trackCount = a.statistics?.trackCount ?? 0;
            final fileCount = a.statistics?.trackFileCount ?? 0;
            return trackCount > 0 && trackCount != fileCount;
        }
      }).toList();

      filtered.sort((a, b) {
        int compare;
        switch (sortOption) {
          case LidarrSortOption.alphabetical:
            compare = (a.sortName ?? a.artistName)
                .toLowerCase()
                .compareTo((b.sortName ?? b.artistName).toLowerCase());
          case LidarrSortOption.dateAdded:
            compare =
                (a.added ?? DateTime(0)).compareTo(b.added ?? DateTime(0));
          case LidarrSortOption.tracks:
            compare = (a.statistics?.percentOfTracks ?? 0)
                .compareTo(b.statistics?.percentOfTracks ?? 0);
          case LidarrSortOption.size:
            compare = (a.statistics?.sizeOnDisk ?? 0)
                .compareTo(b.statistics?.sizeOnDisk ?? 0);
          case LidarrSortOption.qualityProfile:
            compare = (a.qualityProfileId ?? 0)
                .compareTo(b.qualityProfileId ?? 0);
          case LidarrSortOption.metadataProfile:
            compare = (a.metadataProfileId ?? 0)
                .compareTo(b.metadataProfileId ?? 0);
          case LidarrSortOption.type:
            compare = (a.artistType ?? '').compareTo(b.artistType ?? '');
        }
        return ascending ? compare : -compare;
      });

      return filtered;
    },
    orElse: () => [],
  );
});
