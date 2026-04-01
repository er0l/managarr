import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/tautulli_providers.dart';

class TautulliLogsScreen extends ConsumerWidget {
  const TautulliLogsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(tautulliLogsProvider(instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text(
          'Logs',
          style: TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: () => ref.invalidate(tautulliLogsProvider(instance)),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.statusOffline),
              const SizedBox(height: 12),
              const Text('Failed to load logs'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.invalidate(tautulliLogsProvider(instance)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No logs found'));
          }
          return ListView.separated(
            itemCount: logs.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final entry = logs[i];
              final color = _levelColor(entry.level);
              return ListTile(
                dense: true,
                leading: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withAlpha(100)),
                  ),
                  child: Text(
                    entry.level.substring(0, 1),
                    style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                title: Text(
                  entry.message,
                  style: Theme.of(ctx).textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  entry.timestamp,
                  style: Theme.of(ctx)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _levelColor(String level) {
    return switch (level.toUpperCase()) {
      'ERROR' => AppColors.statusOffline,
      'WARNING' => AppColors.statusWarning,
      'DEBUG' => AppColors.blueAccent,
      _ => AppColors.statusOnline,
    };
  }
}
