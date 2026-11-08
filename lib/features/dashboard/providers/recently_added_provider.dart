import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../romm/api/models/romm_rom.dart';
import '../../romm/providers/romm_providers.dart';
import '../../settings/providers/instances_provider.dart';
import '../../settings/providers/ui_prefs_provider.dart';
import '../../tautulli/api/models/tautulli_media_item.dart';
import '../../tautulli/providers/tautulli_providers.dart';

enum RecentKind {
  movies('Movies', 'recentMovies', 'movie'),
  episodes('TV Episodes', 'recentEpisodes', 'show'),
  music('Music', 'recentMusic', 'artist'),
  roms('ROMs', 'recentRoms', null);

  const RecentKind(this.label, this.preference, this.mediaType);
  final String label, preference;
  // Tautulli filters by library type (show/artist), returning episodes/albums.
  final String? mediaType;
}

final dashboardPlexRecentProvider = FutureProvider.autoDispose
    .family<List<TautulliMediaItem>, ({Instance instance, RecentKind kind})>(
      (ref, key) => ref
          .watch(tautulliApiProvider(key.instance))
          .getRecentlyAdded(count: 20, mediaType: key.kind.mediaType),
    );

class RecentAddition {
  const RecentAddition({
    required this.instance,
    required this.kind,
    this.media,
    this.rom,
  });
  final Instance instance;
  final RecentKind kind;
  final TautulliMediaItem? media;
  final RommRom? rom;
  DateTime? get addedAt => media?.addedAtDate ?? rom?.createdAt;
  String get title =>
      rom?.name ??
      (kind == RecentKind.episodes ? media?.grandparentTitle : null) ??
      media?.title ??
      '';
  String get subtitle {
    if (rom != null) return rom!.platformDisplayName;
    final item = media!;
    if (kind == RecentKind.episodes) {
      final season = item.seasonNumber;
      final episode = item.episodeNumber;
      final number = season != null && episode != null
          ? 'S${season.toString().padLeft(2, '0')}E${episode.toString().padLeft(2, '0')} · '
          : '';
      return '$number${item.title}';
    }
    if (kind == RecentKind.music) {
      return item.parentTitle ?? item.grandparentTitle ?? item.year ?? '';
    }
    return item.year ?? '';
  }
}

class RecentSource {
  const RecentSource(this.instance, this.kind, this.items);
  final Instance instance;
  final RecentKind kind;
  final AsyncValue<List<RecentAddition>> items;
}

/// Each source resolves independently. A slow/offline service cannot hide the others.
final dashboardRecentSourcesProvider = Provider.autoDispose<List<RecentSource>>(
  (ref) {
    final grouped = ref.watch(instancesByServiceProvider);
    final prefs = ref.watch(customizationProvider);
    return [
      for (final kind in RecentKind.values)
        if (prefs[kind.preference] == true)
          for (final instance
              in grouped[kind == RecentKind.roms
                      ? ServiceType.romm
                      : ServiceType.tautulli] ??
                  <Instance>[])
            if (instance.enabled)
              RecentSource(
                instance,
                kind,
                kind == RecentKind.roms
                    ? ref
                          .watch(rommRecentlyAddedProvider(instance))
                          .whenData(
                            (roms) => [
                              for (final rom in roms)
                                RecentAddition(
                                  instance: instance,
                                  kind: kind,
                                  rom: rom,
                                ),
                            ],
                          )
                    : ref
                          .watch(
                            dashboardPlexRecentProvider((
                              instance: instance,
                              kind: kind,
                            )),
                          )
                          .whenData(
                            (items) => [
                              for (final item in items)
                                RecentAddition(
                                  instance: instance,
                                  kind: kind,
                                  media: item,
                                ),
                            ],
                          ),
              ),
    ];
  },
);

List<RecentAddition> newestAdditions(
  Iterable<RecentSource> sources, {
  RecentKind? kind,
}) {
  final items = [
    for (final source in sources)
      if (kind == null || source.kind == kind) ...?source.items.valueOrNull,
  ];
  // Preserve source order for servers that omit timestamps.
  final indexed = items.indexed.toList()
    ..sort((a, b) {
      final comparison = (b.$2.addedAt ?? DateTime(1970)).compareTo(
        a.$2.addedAt ?? DateTime(1970),
      );
      return comparison == 0 ? a.$1.compareTo(b.$1) : comparison;
    });
  return indexed.map((item) => item.$2).take(20).toList();
}
