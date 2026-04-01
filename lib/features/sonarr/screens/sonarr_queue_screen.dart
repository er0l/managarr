import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/sonarr_providers.dart';

class SonarrQueueScreen extends ConsumerWidget {
  const SonarrQueueScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(sonarrQueueProvider(instance));

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (queue) {
        final theme = Theme.of(context);
        if (queue.records.isEmpty) {
          return const Center(child: Text('Nothing in the queue'));
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(sonarrQueueProvider(instance)),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: Spacing.s8),
            itemCount: queue.records.length,
            itemBuilder: (context, index) {
              final record = queue.records[index];
              final size = record.size ?? 0;
              final sizeleft = record.sizeleft ?? 0;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.pageHorizontal,
                  vertical: 4,
                ),
                title: Text(
                  record.title ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      '${record.status} • ${sizeleft.toStringAsFixed(1)} GB left',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: size > 0 ? (size - sizeleft) / size : 0,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: AppColors.tealPrimary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
