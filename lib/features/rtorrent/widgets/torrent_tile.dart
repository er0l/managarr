import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../api/models/torrent.dart';

class TorrentTile extends StatelessWidget {
  const TorrentTile({super.key, required this.torrent, this.onTap});

  final RTorrentTorrent torrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(torrent);

    return ListTile(
      onTap: onTap,
      title: Text(
        torrent.name,
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
              value: torrent.percentageDone / 100.0,
              backgroundColor: color.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _StatusBadge(torrent: torrent, color: color),
              const SizedBox(width: 8),
              Text(
                '${torrent.percentageDone}%  •  ${_formatBytes(torrent.completed)} / ${_formatBytes(torrent.size)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          if (torrent.isDownloading || torrent.isSeeding) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                if (torrent.downRate > 0) ...[
                  const Icon(Icons.arrow_downward, size: 12, color: AppColors.statusOnline),
                  Text(
                    ' ${_formatBytes(torrent.downRate)}/s',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.statusOnline),
                  ),
                  const SizedBox(width: 8),
                ],
                if (torrent.upRate > 0) ...[
                  const Icon(Icons.arrow_upward, size: 12, color: AppColors.blueAccent),
                  Text(
                    ' ${_formatBytes(torrent.upRate)}/s',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.blueAccent),
                  ),
                ],
              ],
            ),
          ],
          if (torrent.isError)
            Text(
              torrent.message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.statusOffline),
            ),
        ],
      ),
      isThreeLine: true,
    );
  }

  Color _statusColor(RTorrentTorrent t) {
    if (t.isError) return AppColors.statusOffline;
    if (t.isSeeding) return AppColors.blueAccent;
    if (t.isDownloading) return AppColors.statusOnline;
    if (t.isPaused) return AppColors.statusWarning;
    return AppColors.statusUnknown;
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.torrent, required this.color});
  final RTorrentTorrent torrent;
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
        torrent.statusLabel,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  int i = 0;
  double val = bytes.toDouble();
  while (val >= 1024 && i < units.length - 1) {
    val /= 1024;
    i++;
  }
  return '${val.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}';
}
