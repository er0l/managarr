import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/byte_formatter.dart';
import '../api/nzbget_api.dart';
import '../providers/nzbget_providers.dart';
import '../widgets/nzbget_queue_item_tile.dart';

class NzbgetQueueScreen extends ConsumerWidget {
  const NzbgetQueueScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(nzbgetQueueProvider(instance));
    final statusAsync = ref.watch(nzbgetStatusProvider(instance));

    return queueAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (queue) {
        final status = statusAsync.valueOrNull;
        final api = NzbgetApi.fromInstance(instance);

        return Column(
          children: [
            if (status != null)
              Container(
                padding: const EdgeInsets.all(Spacing.s16),
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
                child: Row(
                  children: [
                    Icon(
                      status.paused ? Icons.pause_circle_outline : Icons.downloading_outlined,
                      color: status.paused ? AppColors.statusWarning : AppColors.statusOnline,
                    ),
                    const SizedBox(width: Spacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.paused ? 'Paused' : '${ByteFormatter.format(status.speed)}/s',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Remaining: ${ByteFormatter.format(status.remainingSize)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () async {
                        if (status.paused) {
                          await api.resumeDownload();
                        } else {
                          await api.pauseDownload();
                        }
                        ref.invalidate(nzbgetStatusProvider(instance));
                      },
                      icon: Icon(status.paused ? Icons.play_arrow : Icons.pause),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(nzbgetQueueProvider(instance));
                  ref.invalidate(nzbgetStatusProvider(instance));
                },
                child: ListView.separated(
                  itemCount: queue.items.length,
                  separatorBuilder: (_, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = queue.items[index];
                    return NzbgetQueueItemTile(
                      item: item,
                      onDelete: () async {
                        await api.deleteJob(item.id);
                        ref.invalidate(nzbgetQueueProvider(instance));
                      },
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
