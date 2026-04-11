import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/radarr_providers.dart';

String _formatEta(DateTime? eta) {
  if (eta == null) return '';
  final diff = eta.difference(DateTime.now());
  if (diff.isNegative) return '';
  if (diff.inHours >= 1) return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  if (diff.inMinutes >= 1) return '${diff.inMinutes}m';
  return '< 1m';
}

class RadarrQueueScreen extends ConsumerWidget {
  const RadarrQueueScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(radarrQueueProvider(instance));

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (queue) {
        final theme = Theme.of(context);
        if (queue.records.isEmpty) {
          return const Center(child: Text('Nothing in the queue'));
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(radarrQueueProvider(instance)),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: Spacing.s8),
            itemCount: queue.records.length,
            itemBuilder: (context, index) {
              final record = queue.records[index];
              final progress = record.size > 0
                  ? max(0.0, (record.size - record.sizeleft) / record.size)
                  : 0.0;
              final isWarning =
                  record.trackedDownloadStatus?.toLowerCase() == 'warning';
              final progressColor =
                  isWarning ? Colors.amber : AppColors.tealPrimary;

              final eta = _formatEta(record.estimatedCompletionTime);
              final subtitleText = [
                record.status,
                if (record.size > 0 && record.sizeleft > 0)
                  '${record.sizeleft.toStringAsFixed(1)} GB left',
                if (eta.isNotEmpty) 'ETA: $eta',
              ].join(' · ');

              // Protocol badge
              final protocol = record.protocol?.toLowerCase();
              final protocolLabel = switch (protocol) {
                'torrent' => 'TOR',
                'usenet' => 'NZB',
                _ => protocol?.toUpperCase() ?? '',
              };
              final protocolColor = switch (protocol) {
                'torrent' => AppColors.orangeAccent,
                'usenet' => AppColors.blueAccent,
                _ => AppColors.statusUnknown,
              };

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.pageHorizontal,
                  vertical: 4,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.title,
                        style:
                            const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (protocolLabel.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: protocolColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: protocolColor.withAlpha(100)),
                        ),
                        child: Text(
                          protocolLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: protocolColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      subtitleText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isWarning
                            ? Colors.amber
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            color: progressColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary),
                        ),
                      ],
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
