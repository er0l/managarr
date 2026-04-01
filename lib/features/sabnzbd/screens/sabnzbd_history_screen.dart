import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/sabnzbd_providers.dart';

class SabnzbdHistoryScreen extends ConsumerWidget {
  const SabnzbdHistoryScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sabnzbdHistoryProvider(instance));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: Spacing.s12),
            Text('$e'),
            const SizedBox(height: Spacing.s8),
            TextButton(
              onPressed: () => ref.invalidate(sabnzbdHistoryProvider(instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No history items found'));
        }
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(sabnzbdHistoryProvider(instance)),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: Spacing.s24),
            itemCount: items.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final item = items[i];
              final color = item.isCompleted
                  ? AppColors.statusOnline
                  : item.isFailed
                      ? AppColors.statusOffline
                      : AppColors.statusWarning;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.pageHorizontal,
                  vertical: Spacing.s4,
                ),
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha(30),
                  child: Icon(
                    item.isCompleted
                        ? Icons.check
                        : item.isFailed
                            ? Icons.close
                            : Icons.access_time,
                    color: color,
                    size: 20,
                  ),
                ),
                title: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  [
                    item.status,
                    item.size,
                    if (item.category.isNotEmpty && item.category != '*')
                      item.category,
                    if (item.completedDateTime != null)
                      _formatRelativeDate(item.completedDateTime!),
                  ].join('  •  '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
