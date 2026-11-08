import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/module_routes.dart';
import '../../../core/widgets/service_avatar.dart';
import '../../../core/widgets/status_dot.dart';
import '../../settings/providers/instances_provider.dart';
import '../../settings/providers/ui_prefs_provider.dart';
import '../providers/health_check_provider.dart';

class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instances = ref.watch(instancesProvider);
    final grid = ref.watch(customizationProvider)['modulesView'] != 'list';
    return instances.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load modules: $e')),
      data: (all) {
        final enabled = all.where((i) => i.enabled).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Modules',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Grid view',
                    isSelected: grid,
                    icon: const Icon(Icons.grid_view_outlined),
                    onPressed: () => ref
                        .read(customizationProvider.notifier)
                        .set('modulesView', 'grid'),
                  ),
                  IconButton(
                    tooltip: 'List view',
                    isSelected: !grid,
                    icon: const Icon(Icons.view_list_outlined),
                    onPressed: () => ref
                        .read(customizationProvider.notifier)
                        .set('modulesView', 'list'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: enabled.isEmpty
                  ? Center(
                      child: TextButton.icon(
                        onPressed: () => context.go('/settings/add-instance'),
                        icon: const Icon(Icons.add),
                        label: const Text('Add a service instance'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        for (final i in enabled) {
                          ref.invalidate(healthCheckProvider(i));
                        }
                        await Future.wait(
                          enabled.map(
                            (i) => ref.read(healthCheckProvider(i).future),
                          ),
                        );
                      },
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns =
                              constraints.maxWidth < 340 ||
                                  MediaQuery.textScalerOf(context).scale(1) >
                                      1.3
                              ? 1
                              : constraints.maxWidth >= 700
                              ? 3
                              : 2;
                          if (!grid) {
                            return ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: enabled.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, index) => _ModuleTile(
                                instance: enabled[index],
                                detailed: true,
                              ),
                            );
                          }
                          return SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final i in enabled)
                                  SizedBox(
                                    width:
                                        (constraints.maxWidth -
                                            32 -
                                            (columns - 1) * 10) /
                                        columns,
                                    child: _ModuleTile(instance: i),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _ModuleTile extends ConsumerWidget {
  const _ModuleTile({required this.instance, this.detailed = false});
  final Instance instance;
  final bool detailed;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ServiceType.values.byName(instance.serviceType);
    final theme = Theme.of(context);
    final health = ref.watch(healthCheckProvider(instance));
    final result = health.valueOrNull;
    final local = ref.watch(useLocalUrlProvider(instance.id));
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
              ServiceAvatar(type: type, size: detailed ? 42 : 32),
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
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (detailed) ...[
                      const SizedBox(height: 6),
                      Text(
                        health.isLoading
                            ? 'Checking connection…'
                            : result?.online == true
                            ? 'Reachable${result?.responseMs != null ? ' · ${result!.responseMs} ms' : ''}'
                            : 'Unreachable',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${local ? 'Local' : 'Remote'} connection${result?.version != null ? ' · v${result!.version}' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              StatusDot(healthAsync: health),
            ],
          ),
        ),
      ),
    );
  }
}
