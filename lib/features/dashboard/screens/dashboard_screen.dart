import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/providers/instances_provider.dart';
import '../models/health_result.dart';
import '../providers/health_check_provider.dart';
import '../widgets/service_status_card.dart';

/// Persists the user's choice between compact grid and full-width list layout.
/// false = compact grid (2-col), true = rows list (1-col full-width).
/// Defaults to true (rows) as it matches the media-first v2 design.
final dashboardListModeProvider = StateProvider<bool>((ref) => true);

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instancesAsync = ref.watch(instancesProvider);
    final listMode = ref.watch(dashboardListModeProvider);

    return instancesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (instances) {
        final enabled = instances.where((i) => i.enabled).toList();
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async {
            for (final i in enabled) {
              ref.invalidate(healthCheckProvider(i));
            }
            await Future.wait(
              enabled.map(
                (i) => ref
                    .read(healthCheckProvider(i).future)
                    .catchError((_) => HealthResult.offline(DateTime.now())),
              ),
            );
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  instanceCount: enabled.length,
                  onlineCount: enabled.isEmpty ? 0 : null,
                ),
              ),
              if (enabled.isEmpty)
                const SliverFillRemaining(child: _NoInstancesHint())
              else if (listMode)
                // ── Rows / list mode ──────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.pageHorizontal,
                    0,
                    Spacing.pageHorizontal,
                    Spacing.s24,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(
                          bottom: index < enabled.length - 1 ? Spacing.cardGap : 0,
                        ),
                        child: ServiceStatusListTile(instance: enabled[index]),
                      ),
                      childCount: enabled.length,
                    ),
                  ),
                )
              else
                // ── Compact / grid mode ───────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.pageHorizontal,
                    0,
                    Spacing.pageHorizontal,
                    Spacing.s24,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => ServiceStatusCard(
                        instance: enabled[index],
                      ),
                      childCount: enabled.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                      crossAxisSpacing: Spacing.cardGap,
                      mainAxisSpacing: Spacing.cardGap,
                      childAspectRatio: 0.88,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({required this.instanceCount, this.onlineCount});
  final int instanceCount;
  final int? onlineCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.tealDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.pageHorizontal,
        Spacing.s20,
        Spacing.pageHorizontal,
        Spacing.s12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Services',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                if (instanceCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$instanceCount instance${instanceCount == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Online count badge — only shown when instances exist.
          if (instanceCount > 0)
            _OnlineBadge(instanceCount: instanceCount),
        ],
      ),
    );
  }
}

/// Shows how many instances are currently online as a green pill badge.
class _OnlineBadge extends ConsumerWidget {
  const _OnlineBadge({required this.instanceCount});
  final int instanceCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instancesAsync = ref.watch(instancesProvider);
    return instancesAsync.maybeWhen(
      data: (instances) {
        final enabled = instances.where((i) => i.enabled).toList();
        if (enabled.isEmpty) return const SizedBox.shrink();
        // Count how many have returned online health results.
        int online = 0;
        for (final inst in enabled) {
          final h = ref.watch(healthCheckProvider(inst));
          h.whenData((r) { if (r.online) online++; });
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.statusOnline.withAlpha(25),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: AppColors.statusOnline.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.statusOnline,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.statusOnlineGlow,
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$online online',
                style: const TextStyle(
                  color: AppColors.statusOnline,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

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
