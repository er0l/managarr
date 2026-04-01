import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/spacing.dart';
import '../models/health_result.dart';
import '../providers/health_check_provider.dart';

class ServiceStatusCard extends ConsumerWidget {
  const ServiceStatusCard({super.key, required this.instance});

  final Instance instance;

  void _onTap(BuildContext context) {
    final type = ServiceType.values.byName(instance.serviceType);
    final route = switch (type) {
      ServiceType.radarr => '/radarr/${instance.id}',
      ServiceType.sonarr => '/sonarr/${instance.id}',
      ServiceType.seer => '/seer/${instance.id}',
      ServiceType.rtorrent => '/rtorrent/${instance.id}',
      ServiceType.sabnzbd => '/sabnzbd/${instance.id}',
      ServiceType.prowlarr => '/prowlarr/${instance.id}',
      ServiceType.lidarr => '/lidarr/${instance.id}',
      ServiceType.tautulli => '/tautulli/${instance.id}',
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
              // Row 1: icon + name + status chip
              Row(
                children: [
                  _ServiceAvatar(type: type),
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
                  _StatusDot(healthAsync: healthAsync),
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
              // Row 2: version / latency / error
              _HealthDetail(healthAsync: healthAsync),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ServiceAvatar extends StatelessWidget {
  const _ServiceAvatar({required this.type});
  final ServiceType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.tealPrimary.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        type.displayName[0],
        style: const TextStyle(
          color: AppColors.tealPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.healthAsync});
  final AsyncValue<HealthResult> healthAsync;

  @override
  Widget build(BuildContext context) {
    return healthAsync.when(
      loading: () => const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.statusUnknown,
        ),
      ),
      error: (e, s) => const _StatusIndicatorDot(color: AppColors.statusOffline),
      data: (result) => _StatusIndicatorDot(
        color: result.online ? AppColors.statusOnline : AppColors.statusOffline,
      ),
    );
  }
}

class _StatusIndicatorDot extends StatelessWidget {
  const _StatusIndicatorDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

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
      error: (e, _) =>
          Text('Error: ${e.toString()}', style: style, maxLines: 2),
      data: (result) {
        if (!result.online) {
          return Row(
            children: [
              const Icon(Icons.cloud_off,
                  size: 12, color: AppColors.statusOffline),
              const SizedBox(width: 4),
              Text('Unreachable',
                  style: style?.copyWith(color: AppColors.statusOffline)),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.version != null)
              Row(
                children: [
                  Icon(Icons.tag,
                      size: 12, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('v${result.version}', style: style),
                ],
              ),
            if (result.responseMs != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.speed,
                      size: 12, color: theme.colorScheme.onSurfaceVariant),
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
