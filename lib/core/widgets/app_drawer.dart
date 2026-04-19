import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../database/models/service_type.dart';
import '../theme/app_colors.dart';
import '../../features/settings/providers/instances_provider.dart';
import '../../features/search/screens/global_search_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(instancesByServiceProvider);
    final theme = Theme.of(context);
    final top = MediaQuery.of(context).padding.top;

    return Drawer(
      child: Column(
        children: [
          // ── Compact header ─────────────────────────────────────────────
          Container(
            color: AppColors.tealPrimary,
            padding: EdgeInsets.fromLTRB(16, top + 14, 16, 14),
            width: double.infinity,
            child: Row(
              children: [
                Image.asset(
                  'assets/icon/icon.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.radar, size: 32, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  'managarr',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Instance list ───────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              children: [
                for (final type in ServiceType.values)
                  if (grouped.containsKey(type) &&
                      grouped[type]!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                      child: Text(
                        type.displayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.tealPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    for (final instance in grouped[type]!)
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        leading: _ServiceIcon(type: type),
                        title: Text(
                          instance.name,
                          style: theme.textTheme.bodyMedium,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          final path = switch (type) {
                            ServiceType.radarr =>
                              '/radarr/${instance.id}',
                            ServiceType.sonarr =>
                              '/sonarr/${instance.id}',
                            ServiceType.lidarr =>
                              '/lidarr/${instance.id}',
                            ServiceType.seer => '/seer/${instance.id}',
                            ServiceType.rtorrent =>
                              '/rtorrent/${instance.id}',
                            ServiceType.sabnzbd =>
                              '/sabnzbd/${instance.id}',
                            ServiceType.prowlarr =>
                              '/prowlarr/${instance.id}',
                            ServiceType.nzbget =>
                              '/nzbget/${instance.id}',
                            ServiceType.tautulli =>
                              '/tautulli/${instance.id}',
                            ServiceType.romm =>
                              '/romm/${instance.id}',
                          };
                          context.push(path);
                        },
                      ),
                    const Divider(height: 1),
                  ],
              ],
            ),
          ),

          // ── Footer ─────────────────────────────────────────────────────
          const Divider(height: 1),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.dashboard_outlined, size: 20),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              context.go('/');
            },
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.search, size: 20),
            title: const Text('Search'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GlobalSearchScreen(),
                ),
              );
            },
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.calendar_month_outlined, size: 20),
            title: const Text('Calendar'),
            onTap: () {
              Navigator.pop(context);
              context.go('/calendar');
            },
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.settings_outlined, size: 20),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              context.go('/settings');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({required this.type});
  final ServiceType type;

  @override
  Widget build(BuildContext context) {
    final asset = _assetForType(type);
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    if (asset != null) {
      return SvgPicture.asset(
        asset,
        width: 20,
        height: 20,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(_iconForType(type), size: 20, color: color);
  }

  String? _assetForType(ServiceType type) => switch (type) {
        ServiceType.radarr   => 'assets/brands/radarr.svg',
        ServiceType.sonarr   => 'assets/brands/sonarr.svg',
        ServiceType.lidarr   => 'assets/brands/lidarr.svg',
        ServiceType.seer     => 'assets/brands/overseerr.svg',
        ServiceType.sabnzbd  => 'assets/brands/sabnzbd.svg',
        ServiceType.nzbget   => 'assets/brands/nzbget.svg',
        ServiceType.tautulli => 'assets/brands/tautulli.svg',
        ServiceType.romm     => 'assets/brands/romm.svg',
        _                    => null,
      };

  IconData _iconForType(ServiceType type) => switch (type) {
        ServiceType.rtorrent  => Icons.cloud_download_outlined,
        ServiceType.prowlarr  => Icons.search_outlined,
        _                     => Icons.settings_outlined,
      };
}
