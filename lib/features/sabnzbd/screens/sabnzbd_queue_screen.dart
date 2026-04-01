import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/sabnzbd_api.dart';
import '../providers/sabnzbd_providers.dart';
import '../widgets/queue_item_tile.dart';

class SabnzbdQueueScreen extends ConsumerWidget {
  const SabnzbdQueueScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(sabnzbdQueueProvider(instance));

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('$e'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(sabnzbdQueueProvider(instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (queue) {
        final api = SabnzbdApi.fromInstance(instance);

        Future<void> doAction(Future<bool> Function() fn) async {
          try {
            await fn();
            ref.invalidate(sabnzbdQueueProvider(instance));
          } catch (_) {}
        }

        return Column(
          children: [
            // Queue summary bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.pageHorizontal,
                vertical: Spacing.s12,
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
              child: Row(
                children: [
                  Icon(
                    queue.paused
                        ? Icons.pause_circle_outline
                        : Icons.downloading_outlined,
                    size: 20,
                    color: queue.paused
                        ? AppColors.statusWarning
                        : AppColors.statusOnline,
                  ),
                  const SizedBox(width: Spacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          queue.paused
                              ? 'Queue Paused'
                              : '${queue.speed}/s • ${_formatSize(queue.sizeLeft)} left',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (!queue.paused)
                          Text(
                            'Estimated time: ${queue.timeLeft}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          )
                        else
                          Text(
                            '${_formatSize(queue.sizeLeft)} remaining',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: Icon(
                      queue.paused ? Icons.play_arrow : Icons.pause,
                      size: 20,
                    ),
                    tooltip: queue.paused ? 'Resume all' : 'Pause all',
                    onPressed: () => doAction(
                      queue.paused ? api.resumeQueue : api.pauseQueue,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: queue.items.isEmpty
                  ? const Center(child: Text('Queue is empty'))
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(sabnzbdQueueProvider(instance)),
                      child: ListView.separated(
                        itemCount: queue.items.length,
                        separatorBuilder: (_, i) => const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final item = queue.items[i];
                          return QueueItemTile(
                            item: item,
                            onPause: () =>
                                doAction(() => api.pauseItem(item.nzoId)),
                            onResume: () =>
                                doAction(() => api.resumeItem(item.nzoId)),
                            onDelete: () => _confirmDelete(
                                ctx, ref, api, item.nzoId),
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

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SabnzbdApi api,
    String nzoId,
  ) async {
    bool deleteFiles = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Delete Item'),
          content: CheckboxListTile(
            title: const Text('Delete downloaded files'),
            value: deleteFiles,
            onChanged: (v) => setS(() => deleteFiles = v ?? false),
            contentPadding: EdgeInsets.zero,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await api.deleteItem(nzoId, deleteFiles: deleteFiles);
      ref.invalidate(sabnzbdQueueProvider(instance));
    }
  }

  String _formatSize(String size) {
    if (size.endsWith(' B') ||
        size.endsWith(' MB') ||
        size.endsWith(' GB') ||
        size.endsWith(' KB')) {
      return size;
    }
    // If it's just a number string from the API (sometimes SABnzbd returns KB as string without unit)
    final val = double.tryParse(size);
    if (val == null) return size;
    if (val < 1024) return '${val.toStringAsFixed(1)} KB';
    if (val < 1024 * 1024) return '${(val / 1024).toStringAsFixed(1)} MB';
    return '${(val / (1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
