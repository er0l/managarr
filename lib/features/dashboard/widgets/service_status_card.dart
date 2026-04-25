import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/spacing.dart';
import '../../../features/lidarr/providers/lidarr_providers.dart';
import '../../../features/nzbget/providers/nzbget_providers.dart';
import '../../../features/radarr/providers/radarr_providers.dart';
import '../../../features/rtorrent/providers/rtorrent_providers.dart';
import '../../../features/sabnzbd/providers/sabnzbd_providers.dart';
import '../../../features/seer/providers/seer_providers.dart';
import '../../../features/sonarr/providers/sonarr_providers.dart';
import '../../../features/tautulli/providers/tautulli_providers.dart';
import '../../../features/romm/providers/romm_providers.dart';
import '../models/health_result.dart';
import '../providers/health_check_provider.dart';

// ---------------------------------------------------------------------------
// Grid card (compact 2-col mode)
// ---------------------------------------------------------------------------

class ServiceStatusCard extends ConsumerWidget {
  const ServiceStatusCard({super.key, required this.instance});

  final Instance instance;

  void _onTap(BuildContext context) {
    final type = ServiceType.values.byName(instance.serviceType);
    final route = switch (type) {
      ServiceType.radarr   => '/radarr/${instance.id}',
      ServiceType.sonarr   => '/sonarr/${instance.id}',
      ServiceType.seer     => '/seer/${instance.id}',
      ServiceType.rtorrent => '/rtorrent/${instance.id}',
      ServiceType.sabnzbd  => '/sabnzbd/${instance.id}',
      ServiceType.prowlarr => '/prowlarr/${instance.id}',
      ServiceType.lidarr   => '/lidarr/${instance.id}',
      ServiceType.tautulli => '/tautulli/${instance.id}',
      ServiceType.romm     => '/romm/${instance.id}',
      _ => null,
    };

    if (route != null) {
      context.push(route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.displayName} module coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthCheckProvider(instance));
    final type = ServiceType.values.byName(instance.serviceType);
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.tealPrimary.withAlpha(20),
        onTap: () => _onTap(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha(20),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(Spacing.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: brand avatar + name + status pill
              Row(
                children: [
                  _ServiceAvatar(type: type, size: 40),
                  const SizedBox(width: Spacing.s8),
                  Expanded(
                    child: Text(
                      type.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: Spacing.s4),
                  _StatusPill(healthAsync: healthAsync),
                ],
              ),
              const SizedBox(height: Spacing.s8),
              // Instance name
              Text(
                instance.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.s12),
              // Version / latency
              _HealthDetail(healthAsync: healthAsync),
              // Service-specific metrics
              _ServiceSummary(instance: instance, type: type),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List tile (rows mode — full-width horizontal card)
// ---------------------------------------------------------------------------

class ServiceStatusListTile extends ConsumerWidget {
  const ServiceStatusListTile({super.key, required this.instance});

  final Instance instance;

  void _onTap(BuildContext context) {
    final type = ServiceType.values.byName(instance.serviceType);
    final route = switch (type) {
      ServiceType.radarr   => '/radarr/${instance.id}',
      ServiceType.sonarr   => '/sonarr/${instance.id}',
      ServiceType.seer     => '/seer/${instance.id}',
      ServiceType.rtorrent => '/rtorrent/${instance.id}',
      ServiceType.sabnzbd  => '/sabnzbd/${instance.id}',
      ServiceType.prowlarr => '/prowlarr/${instance.id}',
      ServiceType.lidarr   => '/lidarr/${instance.id}',
      ServiceType.tautulli => '/tautulli/${instance.id}',
      ServiceType.romm     => '/romm/${instance.id}',
      _ => null,
    };
    if (route != null) {
      context.push(route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${type.displayName} module coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthCheckProvider(instance));
    final type = ServiceType.values.byName(instance.serviceType);
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: theme.colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.tealPrimary.withAlpha(20),
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
          child: Row(
            children: [
              // Brand avatar
              _ServiceAvatar(type: type, size: 44),
              const SizedBox(width: Spacing.s12),
              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Service name + status dot
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            type.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusDot(healthAsync: healthAsync),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Instance name in mono
                    Text(
                      instance.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'JetBrainsMono',
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Stats row
                    _ServiceSummary(instance: instance, type: type),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: service avatar with brand color
// ---------------------------------------------------------------------------

class _ServiceAvatar extends StatelessWidget {
  const _ServiceAvatar({required this.type, this.size = 40});

  final ServiceType type;
  final double size;

  static String _assetForType(ServiceType type) => switch (type) {
        ServiceType.radarr   => 'assets/brands/radarr.svg',
        ServiceType.sonarr   => 'assets/brands/sonarr.svg',
        ServiceType.lidarr   => 'assets/brands/lidarr.svg',
        ServiceType.seer     => 'assets/brands/overseerr.svg',
        ServiceType.sabnzbd  => 'assets/brands/sabnzbd.svg',
        ServiceType.nzbget   => 'assets/brands/nzbget.svg',
        ServiceType.tautulli => 'assets/brands/tautulli.svg',
        ServiceType.romm     => 'assets/brands/romm.svg',
        ServiceType.rtorrent => 'assets/brands/rtorrent.svg',
        ServiceType.prowlarr => 'assets/brands/prowlarr.svg',
      };

  @override
  Widget build(BuildContext context) {
    final bg = type.brandColor;
    final fg = type.brandColorNeedsDarkText
        ? AppColors.textPrimary
        : Colors.white;
    final radius = size * 0.25;
    final iconSize = size * 0.60;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        _assetForType(type),
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: status pill (spec § 8 — radius 4, tinted bg + border, 11sp)
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.healthAsync});

  final AsyncValue<HealthResult> healthAsync;

  @override
  Widget build(BuildContext context) {
    return healthAsync.when(
      loading: () => const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.statusUnknown,
        ),
      ),
      error: (e, _) =>_pill(AppColors.statusOffline, 'Offline'),
      data: (r) => _pill(
        r.online ? AppColors.statusOnline : AppColors.statusOffline,
        r.online ? 'Online' : 'Offline',
      ),
    );
  }

  Widget _pill(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Status dot — glowing circle used in the list tile layout.
// ---------------------------------------------------------------------------

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.healthAsync});

  final AsyncValue<HealthResult> healthAsync;

  @override
  Widget build(BuildContext context) {
    return healthAsync.when(
      loading: () => const SizedBox(
        width: 8,
        height: 8,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: AppColors.statusUnknown,
        ),
      ),
      error: (e, st) => _dot(AppColors.statusOffline, AppColors.statusOfflineGlow),
      data: (r) => _dot(
        r.online ? AppColors.statusOnline : AppColors.statusOffline,
        r.online ? AppColors.statusOnlineGlow : AppColors.statusOfflineGlow,
      ),
    );
  }

  Widget _dot(Color color, Color glow) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(color: glow, blurRadius: 6, spreadRadius: 1),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: service-specific summary metrics
// ---------------------------------------------------------------------------

class _ServiceSummary extends ConsumerWidget {
  const _ServiceSummary({required this.instance, required this.type});

  final Instance instance;
  final ServiceType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final row = _buildRow(context, ref);
    if (row == null) return const SizedBox.shrink();
    return row;
  }

  Widget? _buildRow(BuildContext context, WidgetRef ref) {
    if (type == ServiceType.radarr) {
      final q = ref.watch(radarrQueueProvider(instance));
      return _StatsRow(stats: [
        _Stat(Icons.download_outlined, q.when(
          data: (q) => '${q.totalRecords} queued',
          loading: () => '…', error: (e, _) =>'—',
        )),
      ]);
    }
    if (type == ServiceType.sonarr) {
      final q = ref.watch(sonarrQueueProvider(instance));
      return _StatsRow(stats: [
        _Stat(Icons.download_outlined, q.when(
          data: (q) => '${q.totalRecords} queued',
          loading: () => '…', error: (e, _) =>'—',
        )),
      ]);
    }
    if (type == ServiceType.lidarr) {
      final q = ref.watch(lidarrQueueProvider(instance));
      return _StatsRow(stats: [
        _Stat(Icons.download_outlined, q.when(
          data: (q) => '${q.totalRecords} queued',
          loading: () => '…', error: (e, _) =>'—',
        )),
      ]);
    }
    if (type == ServiceType.tautulli) {
      final a = ref.watch(tautulliActivityProvider(instance));
      return _StatsRow(stats: [
        _Stat(Icons.play_circle_outline, a.when(
          data: (a) => '${a.streamCount} streaming',
          loading: () => '…', error: (e, _) =>'—',
        )),
      ]);
    }
    if (type == ServiceType.seer) {
      final r = ref.watch(seerRequestsProvider(instance));
      return _StatsRow(stats: [
        _Stat(Icons.pending_outlined, r.when(
          data: (reqs) => '${reqs.where((r) => r.status == 1).length} pending',
          loading: () => '…', error: (e, _) =>'—',
        )),
      ]);
    }
    if (type == ServiceType.rtorrent) {
      final t = ref.watch(rtorrentTorrentsProvider(instance));
      return _StatsRow(stats: [
        _Stat(Icons.downloading_outlined, t.when(
          data: (list) => '${list.where((t) => t.isActive).length} active',
          loading: () => '…', error: (e, _) =>'—',
        )),
      ]);
    }
    if (type == ServiceType.sabnzbd) {
      final q = ref.watch(sabnzbdQueueProvider(instance));
      return _StatsRow(stats: [
        _Stat(Icons.download_outlined, q.when(
          data: (q) => '${q.items.length} item${q.items.length == 1 ? '' : 's'}',
          loading: () => '…', error: (e, _) =>'—',
        )),
        _Stat(Icons.speed_outlined, q.when(
          data: (q) {
            final s = q.speed.trim();
            return s.isEmpty || s == '0' ? 'idle' : '$s KB/s';
          },
          loading: () => '…', error: (e, _) =>'—',
        )),
      ]);
    }
    if (type == ServiceType.nzbget) {
      final q = ref.watch(nzbgetQueueProvider(instance));
      return _StatsRow(stats: [
        _Stat(Icons.download_outlined, q.when(
          data: (q) => '${q.items.length} queued',
          loading: () => '…', error: (e, _) =>'—',
        )),
      ]);
    }
    if (type == ServiceType.romm) {
      final p = ref.watch(rommPlatformsProvider(instance));
      return _StatsRow(stats: [
        _Stat(Icons.videogame_asset_outlined, p.when(
          data: (list) => '${list.length} platforms',
          loading: () => '…', error: (e, _) =>'—',
        )),
      ]);
    }
    return null; // Prowlarr
  }
}

class _Stat {
  const _Stat(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});
  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 10,
    );
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final s in stats)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(s.icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 3),
              Text(s.label, style: style),
            ],
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared: health detail (version + latency)
// ---------------------------------------------------------------------------

class _HealthDetail extends StatelessWidget {
  const _HealthDetail({required this.healthAsync});
  final AsyncValue<HealthResult> healthAsync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return healthAsync.when(
      loading: () => Text('Checking…', style: style),
      error: (e, _) => Text('Error: ${e.toString()}', style: style, maxLines: 2),
      data: (result) {
        if (!result.online) {
          return Row(
            children: [
              const Icon(Icons.cloud_off, size: 12, color: AppColors.statusOffline),
              const SizedBox(width: 4),
              Text('Unreachable', style: style?.copyWith(color: AppColors.statusOffline)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.version != null)
              Row(
                children: [
                  Icon(Icons.tag, size: 12, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('v${result.version}', style: style),
                ],
              ),
            if (result.responseMs != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.speed, size: 12, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${result.responseMs}ms', style: style),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
