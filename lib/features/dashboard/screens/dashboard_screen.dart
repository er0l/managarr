import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../calendar/providers/calendar_providers.dart';
import '../../lidarr/providers/lidarr_providers.dart';
import '../../radarr/providers/radarr_providers.dart';
import '../../rtorrent/providers/rtorrent_providers.dart';
import '../../seer/providers/seer_providers.dart';
import '../../settings/providers/instances_provider.dart';
import '../../sonarr/providers/sonarr_providers.dart';
import '../../tautulli/providers/tautulli_providers.dart';
import '../models/health_result.dart';
import '../providers/health_check_provider.dart';
import '../widgets/sections/downloads_section.dart';
import '../widgets/sections/now_playing_section.dart';
import '../widgets/sections/requests_section.dart';
import '../widgets/sections/status_strip.dart';
import '../widgets/sections/upcoming_section.dart';

/// Content-hub dashboard: service status strip on top, followed by
/// Now Playing, Downloads, Upcoming and Requests sections. Sections
/// collapse automatically when no relevant service is configured.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _refresh(WidgetRef ref, List<Instance> enabled) async {
    for (final instance in enabled) {
      ref.invalidate(healthCheckProvider(instance));
      final type = ServiceType.values.byName(instance.serviceType);
      switch (type) {
        case ServiceType.radarr:
          ref.invalidate(radarrQueueProvider(instance));
        case ServiceType.sonarr:
          ref.invalidate(sonarrQueueProvider(instance));
        case ServiceType.lidarr:
          ref.invalidate(lidarrQueueProvider(instance));
        case ServiceType.rtorrent:
          ref.invalidate(rtorrentTorrentsProvider(instance));
        case ServiceType.tautulli:
          ref.invalidate(tautulliActivityProvider(instance));
        case ServiceType.seer:
          ref.invalidate(seerRequestsProvider(instance));
        case ServiceType.prowlarr || ServiceType.romm:
          break;
      }
    }
    ref.invalidate(unifiedCalendarProvider);
    // Await the health checks so the refresh spinner reflects real work.
    await Future.wait(
      enabled.map(
        (i) => ref
            .read(healthCheckProvider(i).future)
            .catchError((_) => HealthResult.offline(DateTime.now())),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instancesAsync = ref.watch(instancesProvider);

    return instancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (instances) {
        final enabled = instances.where((i) => i.enabled).toList();

        List<Instance> ofType(ServiceType type) => enabled
            .where((i) => i.serviceType == type.name)
            .toList();

        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () => _refresh(ref, enabled),
          child: enabled.isEmpty
              ? const CustomScrollView(
                  slivers: [
                    SliverFillRemaining(child: _NoInstancesHint()),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.only(
                    top: Spacing.s16,
                    bottom: Spacing.s24,
                  ),
                  children: [
                    StatusStrip(instances: enabled),
                    NowPlayingSection(
                        instances: ofType(ServiceType.tautulli)),
                    const DownloadsSection(),
                    const UpcomingSection(),
                    RequestsSection(instances: ofType(ServiceType.seer)),
                  ],
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _NoInstancesHint extends StatelessWidget {
  const _NoInstancesHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radar_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
            ),
            const SizedBox(height: Spacing.s16),
            Text(
              'Nothing here yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.s8),
            Text(
              'Go to Settings and add a service instance to get started.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s24),
            FilledButton.icon(
              onPressed: () => context.go('/settings'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orangeAccent,
                foregroundColor: AppColors.textOnPrimary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.s24, vertical: 14),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Instance'),
            ),
          ],
        ),
      ),
    );
  }
}
