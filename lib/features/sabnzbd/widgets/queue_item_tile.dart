import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../api/models/queue_item.dart';

class QueueItemTile extends StatelessWidget {
  const QueueItemTile({
    super.key,
    required this.item,
    required this.onPause,
    required this.onResume,
    required this.onDelete,
  });

  final SabnzbdQueueItem item;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = item.isPaused ? AppColors.statusWarning : AppColors.statusOnline;

    return ListTile(
      title: Text(
        item.filename,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: item.percentage / 100.0,
              minHeight: 4,
              backgroundColor: color.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _Badge(label: item.status, color: color),
              const SizedBox(width: 8),
              Text(
                '${item.percentage.toStringAsFixed(1)}%  •  ${item.sizeLeft} left',
                style: theme.textTheme.bodySmall,
              ),
              if (item.category.isNotEmpty && item.category != '*') ...[
                const SizedBox(width: 8),
                Text(
                  item.category,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
          if (item.isDownloading && item.timeLeft != '0:00:00')
            Text(
              '${item.timeLeft} remaining',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<_Action>(
        onSelected: (a) => switch (a) {
          _Action.pause => onPause(),
          _Action.resume => onResume(),
          _Action.delete => onDelete(),
        },
        itemBuilder: (_) => [
          if (item.isDownloading)
            const PopupMenuItem(
              value: _Action.pause,
              child: ListTile(
                  leading: Icon(Icons.pause), title: Text('Pause')),
            ),
          if (item.isPaused)
            const PopupMenuItem(
              value: _Action.resume,
              child: ListTile(
                  leading: Icon(Icons.play_arrow), title: Text('Resume')),
            ),
          const PopupMenuItem(
            value: _Action.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Action { pause, resume, delete }

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
