import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/router/module_routes.dart';
import '../../../core/widgets/service_avatar.dart';
import '../../../core/widgets/status_dot.dart';
import '../providers/health_check_provider.dart';

/// Visible module names and instance names make Dashboard a useful home screen.
class ModuleLauncher extends StatelessWidget {
  const ModuleLauncher({super.key, required this.instances});
  final List<Instance> instances;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Modules',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.go('/settings'),
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth < 300 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3
                ? 1
                : constraints.maxWidth >= 700
                ? 3
                : 2;
            final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final instance in instances)
                  SizedBox(
                    width: width,
                    child: _ModuleTile(instance: instance),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

class _ModuleTile extends ConsumerWidget {
  const _ModuleTile({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ServiceType.values.byName(instance.serviceType);
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(moduleRouteFor(type, instance.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ServiceAvatar(type: type, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type.displayName, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      instance.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              StatusDot(healthAsync: ref.watch(healthCheckProvider(instance))),
            ],
          ),
        ),
      ),
    );
  }
}
