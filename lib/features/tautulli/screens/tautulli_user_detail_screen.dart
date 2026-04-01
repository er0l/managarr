import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/tautulli_providers.dart';

class TautulliUserDetailScreen extends ConsumerWidget {
  const TautulliUserDetailScreen({
    super.key,
    required this.instance,
    required this.userId,
    required this.displayName,
  });

  final Instance instance;
  final int userId;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      tautulliUserDetailProvider((instance: instance, userId: userId)),
    );
    final historyAsync = ref.watch(
      tautulliUserHistoryProvider((instance: instance, userId: userId)),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Text(
          displayName,
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (detail) {
          return CustomScrollView(
            slivers: [
              // Stats header
              SliverToBoxAdapter(
                child: Container(
                  color: AppColors.tealPrimary.withAlpha(10),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.orangeAccent.withAlpha(30),
                        child: const Icon(Icons.person_outline,
                            color: AppColors.orangeAccent, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        detail.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (detail.username != detail.displayName)
                        Text(
                          '@${detail.username}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatChip(
                            label: 'Plays',
                            value: '${detail.totalPlays}',
                            icon: Icons.play_circle_outline,
                          ),
                          _StatChip(
                            label: 'Watch Time',
                            value: detail.totalTimeFormatted,
                            icon: Icons.schedule,
                          ),
                          if (detail.lastSeenAt != null)
                            _StatChip(
                              label: 'Last Seen',
                              value: DateFormat.MMMd()
                                  .format(detail.lastSeenAt!),
                              icon: Icons.visibility_outlined,
                            ),
                        ],
                      ),
                      if (detail.lastPlayed != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Last played: ${detail.lastPlayed}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // History
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Watch History',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(
                          color: AppColors.tealPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              historyAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, s) => SliverToBoxAdapter(
                    child: Center(child: Text('Error: $e'))),
                data: (history) {
                  if (history.items.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('No history found'),
                        ),
                      ),
                    );
                  }
                  return SliverList.separated(
                    itemCount: history.items.length,
                    separatorBuilder: (_, i) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = history.items[i];
                      final dateStr = item.stoppedAt != null
                          ? DateFormat.MMMd().add_Hm().format(item.stoppedAt!)
                          : '—';
                      return ListTile(
                        title: Text(
                          item.title ?? 'Unknown',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          dateStr,
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                        trailing: Text(
                          '${item.percentComplete}%',
                          style: Theme.of(ctx)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: item.percentComplete >= 90
                                    ? AppColors.statusOnline
                                    : AppColors.statusWarning,
                              ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.tealPrimary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
