import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/byte_formatter.dart';
import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/romm_platform.dart';
import '../providers/romm_providers.dart';

/// Server statistics — overview cards plus a size-per-platform breakdown.
class RommStatsScreen extends ConsumerWidget {
  const RommStatsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(rommStatsProvider(instance));
    final platformsAsync = ref.watch(rommPlatformsProvider(instance));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Statistics',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.invalidate(rommStatsProvider(instance));
              ref.invalidate(rommPlatformsProvider(instance));
            },
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.statusOffline),
              const SizedBox(height: 12),
              const Text('Failed to load statistics'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(rommStatsProvider(instance)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) {
          final theme = Theme.of(context);
          return RefreshIndicator(
            color: AppColors.tealPrimary,
            onRefresh: () async {
              ref.invalidate(rommStatsProvider(instance));
              ref.invalidate(rommPlatformsProvider(instance));
            },
            child: ListView(
              padding: const EdgeInsets.all(Spacing.pageHorizontal),
              children: [
                Text(
                  'Overview',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Spacing.s12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: Spacing.cardGap,
                  crossAxisSpacing: Spacing.cardGap,
                  childAspectRatio: 1.9,
                  children: [
                    _StatCard(
                      icon: Icons.videogame_asset_outlined,
                      label: 'ROMs',
                      value: '${stats.totalRoms}',
                    ),
                    _StatCard(
                      icon: Icons.dns_outlined,
                      label: 'Platforms',
                      value: '${stats.totalPlatforms}',
                    ),
                    _StatCard(
                      icon: Icons.sd_storage_outlined,
                      label: 'Library Size',
                      value: stats.formattedSize.isEmpty
                          ? '—'
                          : stats.formattedSize,
                    ),
                    _StatCard(
                      icon: Icons.save_outlined,
                      label: 'Saves',
                      value: '${stats.totalSaves}',
                    ),
                    _StatCard(
                      icon: Icons.bookmark_outline,
                      label: 'States',
                      value: '${stats.totalStates}',
                    ),
                    _StatCard(
                      icon: Icons.image_outlined,
                      label: 'Screenshots',
                      value: '${stats.totalScreenshots}',
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.s24),
                Text(
                  'Size per Platform',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: Spacing.s12),
                platformsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(Spacing.s24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    'Could not load platforms',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  data: (platforms) => _PlatformSizeList(
                    platforms: [
                      ...platforms.where((p) => p.fsSizeBytes > 0)
                    ]..sort(
                        (a, b) => b.fsSizeBytes.compareTo(a.fsSizeBytes)),
                  ),
                ),
                const SizedBox(height: Spacing.s24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.s16),
        child: Row(
          children: [
            Icon(icon, size: 26, color: AppColors.tealPrimary),
            const SizedBox(width: Spacing.s12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal bars sized relative to the largest platform.
class _PlatformSizeList extends StatelessWidget {
  const _PlatformSizeList({required this.platforms});

  final List<RommPlatform> platforms;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (platforms.isEmpty) {
      return Text(
        'No size information available',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final maxSize = platforms.first.fsSizeBytes;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s16),
        child: Column(
          children: [
            for (final p in platforms) ...[
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      p.displayName,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: Spacing.s8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: maxSize > 0
                              ? p.fsSizeBytes / maxSize
                              : 0,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: AppColors.tealPrimary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      ByteFormatter.format(p.fsSizeBytes),
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  ),
                ],
              ),
              if (p != platforms.last) const SizedBox(height: Spacing.s12),
            ],
          ],
        ),
      ),
    );
  }
}
