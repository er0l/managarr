import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../settings/providers/instances_provider.dart';
import '../api/models/torrent.dart';
import '../api/rtorrent_api.dart';

enum RTorrentSort {
  name,
  status,
  size,
  dateDone,
  dateAdded,
  percentDownloaded,
  downloadSpeed,
  uploadSpeed,
  ratio,
}

enum RTorrentStatusFilter { all, downloading, seeding, active, inactive }

// Per-instance sort/filter/search state
final rtorrentSearchQueryProvider =
    StateProvider.family<String, int>((ref, id) => '');

final rtorrentSortProvider =
    StateProvider.family<RTorrentSort, int>((ref, id) => RTorrentSort.name);

final rtorrentStatusFilterProvider =
    StateProvider.family<RTorrentStatusFilter, int>(
        (ref, id) => RTorrentStatusFilter.all);

final rtorrentLabelFilterProvider =
    StateProvider.family<String, int>((ref, id) => '');

// Raw torrent list from API
final rtorrentTorrentsProvider =
    FutureProvider.autoDispose.family<List<RTorrentTorrent>, Instance>(
        (ref, instance) async {
  final api = RTorrentApi.fromInstance(instance);
  return api.getTorrents();
});

// Sorted/filtered view
final rtorrentFilteredProvider = Provider.autoDispose
    .family<List<RTorrentTorrent>, Instance>((ref, instance) {
  final async = ref.watch(rtorrentTorrentsProvider(instance));
  return async.when(
    data: (torrents) {
      final sort = ref.watch(rtorrentSortProvider(instance.id));
      final statusFilter =
          ref.watch(rtorrentStatusFilterProvider(instance.id));
      final labelFilter = ref.watch(rtorrentLabelFilterProvider(instance.id));

      var list = List<RTorrentTorrent>.from(torrents);

      // Status filter
      list = switch (statusFilter) {
        RTorrentStatusFilter.downloading =>
          list.where((t) => t.isDownloading).toList(),
        RTorrentStatusFilter.seeding =>
          list.where((t) => t.isSeeding).toList(),
        RTorrentStatusFilter.active =>
          list.where((t) => t.isActive).toList(),
        RTorrentStatusFilter.inactive =>
          list.where((t) => !t.isActive).toList(),
        _ => list,
      };

      // Label filter
      if (labelFilter.isNotEmpty) {
        list = list.where((t) => t.label == labelFilter).toList();
      }

      // Search filter
      final q = ref.watch(rtorrentSearchQueryProvider(instance.id));
      if (q.isNotEmpty) {
        list = list
            .where((t) => t.name.toLowerCase().contains(q.toLowerCase()))
            .toList();
      }

      // Sort
      switch (sort) {
        case RTorrentSort.name:
          list.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        case RTorrentSort.status:
          list.sort((a, b) => a.statusLabel.compareTo(b.statusLabel));
        case RTorrentSort.size:
          list.sort((a, b) => b.size.compareTo(a.size));
        case RTorrentSort.dateDone:
          list.sort((a, b) => b.dateDone.compareTo(a.dateDone));
        case RTorrentSort.dateAdded:
          list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        case RTorrentSort.percentDownloaded:
          list.sort(
              (a, b) => b.percentageDone.compareTo(a.percentageDone));
        case RTorrentSort.downloadSpeed:
          list.sort((a, b) => b.downRate.compareTo(a.downRate));
        case RTorrentSort.uploadSpeed:
          list.sort((a, b) => b.upRate.compareTo(a.upRate));
        case RTorrentSort.ratio:
          list.sort((a, b) => b.ratio.compareTo(a.ratio));
      }

      return list;
    },
    loading: () => [],
    error: (e, s) => [],
  );
});

// Global stats for an instance
final rtorrentGlobalStatsProvider = Provider.autoDispose
    .family<RTorrentGlobalStats, Instance>((ref, instance) {
  final async = ref.watch(rtorrentTorrentsProvider(instance));
  final torrents = async.valueOrNull ?? [];

  int down = 0;
  int up = 0;
  int downloading = 0;
  int seeding = 0;
  int active = 0;

  for (final t in torrents) {
    down += t.downRate;
    up += t.upRate;
    if (t.isDownloading) downloading++;
    if (t.isSeeding) seeding++;
    if (t.isActive) active++;
  }

  return RTorrentGlobalStats(
    totalDownRate: down,
    totalUpRate: up,
    totalTorrents: torrents.length,
    downloadingCount: downloading,
    seedingCount: seeding,
    activeCount: active,
  );
});

// Aggregated stats for all enabled rTorrent instances
final rtorrentAggregatedStatsProvider = Provider.autoDispose<RTorrentGlobalStats>((ref) {
  final instancesAsync = ref.watch(instancesProvider);
  final instances = instancesAsync.valueOrNull ?? [];
  final rtorrentInstances = instances.where((i) => i.serviceType == 'rtorrent' && i.enabled);

  int down = 0;
  int up = 0;
  int total = 0;
  int downloading = 0;
  int seeding = 0;
  int active = 0;

  for (final instance in rtorrentInstances) {
    final stats = ref.watch(rtorrentGlobalStatsProvider(instance));
    down += stats.totalDownRate;
    up += stats.totalUpRate;
    total += stats.totalTorrents;
    downloading += stats.downloadingCount;
    seeding += stats.seedingCount;
    active += stats.activeCount;
  }

  return RTorrentGlobalStats(
    totalDownRate: down,
    totalUpRate: up,
    totalTorrents: total,
    downloadingCount: downloading,
    seedingCount: seeding,
    activeCount: active,
  );
});

class RTorrentGlobalStats {
  final int totalDownRate;
  final int totalUpRate;
  final int totalTorrents;
  final int downloadingCount;
  final int seedingCount;
  final int activeCount;

  const RTorrentGlobalStats({
    required this.totalDownRate,
    required this.totalUpRate,
    required this.totalTorrents,
    required this.downloadingCount,
    required this.seedingCount,
    required this.activeCount,
  });
}
