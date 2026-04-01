import 'package:flutter/material.dart';

import '../../../core/config/spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/byte_formatter.dart';
import '../api/models/nzbget_queue.dart';

class NzbgetQueueItemTile extends StatelessWidget {
  const NzbgetQueueItemTile({
    super.key,
    required this.item,
    required this.onDelete,
  });

  final NzbgetQueueItem item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final progress = item.fileSize > 0
        ? (item.fileSize - item.remainingSize) / item.fileSize
        : 0.0;

    return ListTile(
      title: Text(
        item.name,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.s4),
          Text(
            '${item.status} • ${item.category}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: Spacing.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.tealPrimary.withAlpha(20),
              color: AppColors.tealPrimary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: Spacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              Text(
                '${ByteFormatter.format(item.fileSize - item.remainingSize)} / ${ByteFormatter.format(item.fileSize)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 20),
        onPressed: onDelete,
      ),
    );
  }
}
