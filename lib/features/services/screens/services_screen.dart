import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/spacing.dart';
import '../../settings/providers/instances_provider.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = ref.watch(instancesByServiceProvider);
    final theme = Theme.of(context);

    final populated = ServiceType.values
        .where((t) => grouped.containsKey(t) && grouped[t]!.isNotEmpty)
        .toList();

    if (populated.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.grid_view_outlined,
                size: 64,
                color: AppColors.textSecondary.withAlpha(80),
              ),
              const SizedBox(height: Spacing.s16),
              Text(
                'No services configured',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: Spacing.s8),
              Text(
                'Go to Settings and add a service instance.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
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
                    horizontal: Spacing.s24, vertical: 14,
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Instance'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      children: [
        for (final type in populated) ...[
          _SectionHeader(type: type),
          for (final instance in grouped[type]!)
            _InstanceTile(instance: instance, type: type),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.type});
  final ServiceType type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.pageHorizontal, Spacing.s20,
        Spacing.pageHorizontal, Spacing.s4,
      ),
      child: Text(
        type.displayName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.tealPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _InstanceTile extends StatelessWidget {
  const _InstanceTile({required this.instance, required this.type});

  final Instance instance;
  final ServiceType type;

  /// Returns the GoRouter path for supported modules, else null.
  String? get _routePath => switch (type) {
        ServiceType.radarr => '/radarr/${instance.id}',
        ServiceType.sonarr => '/sonarr/${instance.id}',
        ServiceType.lidarr => '/lidarr/${instance.id}',
        ServiceType.seer => '/seer/${instance.id}',
        ServiceType.rtorrent => '/rtorrent/${instance.id}',
        ServiceType.sabnzbd => '/sabnzbd/${instance.id}',
        ServiceType.prowlarr => '/prowlarr/${instance.id}',
        ServiceType.nzbget => '/nzbget/${instance.id}',
        ServiceType.tautulli => '/tautulli/${instance.id}',
      };

  bool get _isSupported => _routePath != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.pageHorizontal,
        vertical: Spacing.s4,
      ),
      onTap: () {
        final path = _routePath;
        if (path != null) {
          context.push(path, extra: instance);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${type.displayName} module coming soon'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      leading: Container(
        width: 44,
        height: 44,
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
      ),
      title: Text(
        instance.name,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        instance.baseUrl,
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _isSupported
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : const Tooltip(
              message: 'Coming soon',
              child: Icon(
                Icons.lock_outline,
                size: 18,
                color: AppColors.statusUnknown,
              ),
            ),
    );
  }
}
