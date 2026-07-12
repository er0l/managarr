import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/byte_formatter.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../lidarr/providers/lidarr_providers.dart';
import '../../nzbget/providers/nzbget_providers.dart';
import '../../radarr/providers/radarr_providers.dart';
import '../../rtorrent/providers/rtorrent_providers.dart';
import '../../sabnzbd/providers/sabnzbd_providers.dart';
import '../../settings/providers/instances_provider.dart';
import '../../sonarr/providers/sonarr_providers.dart';

/// A single in-flight download normalized across all download-capable
/// services for the dashboard Downloads section.
class DashboardDownload {
  const DashboardDownload({
    required this.title,
    this.progress,
    this.detail,
  });

  final String title;

  /// 0..1 fraction; null when the source doesn't report progress.
  final double? progress;

  /// Secondary line — size left, ETA, status, …
  final String? detail;
}

/// Per-instance download queue snapshot. Each instance resolves
/// independently so one unreachable service never blocks the rest.
class InstanceDownloads {
  const InstanceDownloads({
    required this.instance,
    required this.type,
    required this.items,
    this.speedLabel,
  });

  final Instance instance;
  final ServiceType type;
  final AsyncValue<List<DashboardDownload>> items;

  /// Client-level download speed (SABnzbd/NZBGet/rTorrent), when known.
  final String? speedLabel;
}

/// Merges download queues across all enabled instances of every
/// download-capable service. Sync provider over cached AsyncValues —
/// same failure-tolerant pattern as [rtorrentAggregatedStatsProvider].
final dashboardDownloadsProvider =
    Provider.autoDispose<List<InstanceDownloads>>((ref) {
  final grouped = ref.watch(instancesByServiceProvider);
  final result = <InstanceDownloads>[];

  for (final instance in _enabled(grouped[ServiceType.radarr])) {
    result.add(InstanceDownloads(
      instance: instance,
      type: ServiceType.radarr,
      items: ref.watch(radarrQueueProvider(instance)).whenData(
            (q) => [
              for (final r in q.records)
                DashboardDownload(
                  title: r.title,
                  progress: _arrProgress(r.size, r.sizeleft),
                  detail: _arrDetail(r.sizeleft, r.status),
                ),
            ],
          ),
    ));
  }

  for (final instance in _enabled(grouped[ServiceType.sonarr])) {
    result.add(InstanceDownloads(
      instance: instance,
      type: ServiceType.sonarr,
      items: ref.watch(sonarrQueueProvider(instance)).whenData(
            (q) => [
              for (final r in q.records)
                DashboardDownload(
                  title: r.title ?? 'Unknown',
                  progress: _arrProgress(r.size, r.sizeleft),
                  detail: _arrDetail(r.sizeleft, r.status),
                ),
            ],
          ),
    ));
  }

  for (final instance in _enabled(grouped[ServiceType.lidarr])) {
    result.add(InstanceDownloads(
      instance: instance,
      type: ServiceType.lidarr,
      items: ref.watch(lidarrQueueProvider(instance)).whenData(
            (q) => [
              for (final r in q.records)
                DashboardDownload(
                  title: r.title ?? 'Unknown',
                  progress: _arrProgress(r.size, r.sizeleft),
                  detail: _arrDetail(r.sizeleft, r.status),
                ),
            ],
          ),
    ));
  }

  for (final instance in _enabled(grouped[ServiceType.sabnzbd])) {
    final queueAsync = ref.watch(sabnzbdQueueProvider(instance));
    final speed = queueAsync.valueOrNull?.speed.trim();
    result.add(InstanceDownloads(
      instance: instance,
      type: ServiceType.sabnzbd,
      speedLabel: (speed == null || speed.isEmpty || speed == '0')
          ? null
          : '$speed KB/s',
      items: queueAsync.whenData(
        (q) => [
          for (final item in q.items)
            DashboardDownload(
              title: item.filename,
              progress: (item.percentage / 100).clamp(0.0, 1.0),
              detail: item.timeLeft.isEmpty ? item.status : item.timeLeft,
            ),
        ],
      ),
    ));
  }

  for (final instance in _enabled(grouped[ServiceType.nzbget])) {
    final status = ref.watch(nzbgetStatusProvider(instance)).valueOrNull;
    result.add(InstanceDownloads(
      instance: instance,
      type: ServiceType.nzbget,
      speedLabel: (status == null || status.speed <= 0)
          ? null
          : '${ByteFormatter.format(status.speed)}/s',
      items: ref.watch(nzbgetQueueProvider(instance)).whenData(
            (q) => [
              for (final item in q.items)
                DashboardDownload(
                  title: item.name,
                  progress: item.fileSize > 0
                      ? (1 - item.remainingSize / item.fileSize)
                          .clamp(0.0, 1.0)
                      : null,
                  detail:
                      '${ByteFormatter.format(item.remainingSize)} left',
                ),
            ],
          ),
    ));
  }

  for (final instance in _enabled(grouped[ServiceType.rtorrent])) {
    final stats = ref.watch(rtorrentGlobalStatsProvider(instance));
    result.add(InstanceDownloads(
      instance: instance,
      type: ServiceType.rtorrent,
      speedLabel: stats.totalDownRate > 0
          ? '${ByteFormatter.format(stats.totalDownRate)}/s'
          : null,
      items: ref.watch(rtorrentTorrentsProvider(instance)).whenData(
            (list) => [
              for (final t in list.where((t) => t.isDownloading))
                DashboardDownload(
                  title: t.name,
                  progress: (t.percentageDone / 100).clamp(0.0, 1.0),
                  detail: t.downRate > 0
                      ? '${ByteFormatter.format(t.downRate)}/s'
                      : t.statusLabel,
                ),
            ],
          ),
    ));
  }

  return result;
});

List<Instance> _enabled(List<Instance>? instances) =>
    (instances ?? const []).where((i) => i.enabled).toList();

double? _arrProgress(double? size, double? sizeleft) {
  if (size == null || sizeleft == null || size <= 0) return null;
  return (1 - sizeleft / size).clamp(0.0, 1.0);
}

String? _arrDetail(double? sizeleft, String? status) {
  if (sizeleft != null && sizeleft > 0) {
    return '${ByteFormatter.format(sizeleft.round())} left';
  }
  return status;
}
