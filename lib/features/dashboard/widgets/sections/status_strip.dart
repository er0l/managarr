import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/spacing.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/models/service_type.dart';
import '../../../../core/router/module_routes.dart';
import '../../../../core/widgets/service_avatar.dart';
import '../../../../core/widgets/status_dot.dart';
import '../../providers/health_check_provider.dart';

/// Horizontal strip of per-instance chips: brand avatar with a status dot,
/// instance name below. Tap opens the module, long-press opens Settings.
class StatusStrip extends StatelessWidget {
  const StatusStrip({super.key, required this.instances});

  final List<Instance> instances;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.pageHorizontal,
        ),
        itemCount: instances.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: Spacing.s16),
        itemBuilder: (context, index) {
          if (index == instances.length) return const _ManageChip();
          return _InstanceChip(instance: instances[index]);
        },
      ),
    );
  }
}

class _InstanceChip extends ConsumerWidget {
  const _InstanceChip({required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ServiceType.values.byName(instance.serviceType);
    final healthAsync = ref.watch(healthCheckProvider(instance));
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push(moduleRouteFor(type, instance.id)),
      onLongPress: () => context.go('/settings'),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ServiceAvatar(type: type, size: 48),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.scaffoldBackgroundColor,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: StatusDot(healthAsync: healthAsync),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              instance.name,
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManageChip extends StatelessWidget {
  const _ManageChip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go('/settings'),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.tune,
                size: 22,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'Manage',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
