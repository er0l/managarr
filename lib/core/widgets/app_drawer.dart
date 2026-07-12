import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../database/app_database.dart';
import '../database/models/service_type.dart';
import '../router/module_routes.dart';
import '../theme/app_colors.dart';
import 'service_avatar.dart';
import 'status_dot.dart';
import '../../features/dashboard/providers/health_check_provider.dart';
import '../../features/settings/providers/instances_provider.dart';
import '../../features/search/screens/global_search_screen.dart';

/// Module launcher drawer — branded entries per service with per-instance
/// health dots. Health results come from the shared (kept-alive)
/// [healthCheckProvider] cache; opening the drawer fires no new checks
/// while the dashboard's results are fresh.
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
          // ── Header ─────────────────────────────────────────────────────
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

          // ── Modules ─────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (final type in ServiceType.values)
                  if (grouped[type]?.isNotEmpty ?? false)
                    ..._moduleEntries(context, ref, theme, type,
                        grouped[type]!),
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

  /// Module row (branded avatar + name). A single instance makes the row
  /// itself the navigation target; multiple instances get indented sub-rows.
  List<Widget> _moduleEntries(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ServiceType type,
    List<Instance> instances,
  ) {
    void open(Instance instance) {
      Navigator.pop(context);
      context.push(moduleRouteFor(type, instance.id));
    }

    Widget trailingFor(Instance instance) => instance.enabled
        ? StatusDot(healthAsync: ref.watch(healthCheckProvider(instance)))
        : const DisabledDot();

    if (instances.length == 1) {
      final instance = instances.first;
      return [
        ListTile(
          visualDensity: VisualDensity.compact,
          leading: ServiceAvatar(type: type, size: 32),
          title: Text(
            type.displayName,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            instance.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: trailingFor(instance),
          onTap: () => open(instance),
        ),
      ];
    }

    return [
      ListTile(
        visualDensity: VisualDensity.compact,
        leading: ServiceAvatar(type: type, size: 32),
        title: Text(
          type.displayName,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      for (final instance in instances)
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.only(left: 56, right: 16),
          title: Text(instance.name, style: theme.textTheme.bodyMedium),
          trailing: trailingFor(instance),
          onTap: () => open(instance),
        ),
    ];
  }
}
