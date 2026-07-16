import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/byte_formatter.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../services/romm_download_history.dart';

/// History of ROMs downloaded to this device.
class RommDownloadsScreen extends ConsumerWidget {
  const RommDownloadsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(rommDownloadHistoryProvider);
    final db = ref.read(dbProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Downloads',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Clear history',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear download history'),
                  content: const Text(
                      'Remove all entries? Downloaded files stay on your '
                      'device.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.statusOffline),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await RommDownloadHistory.clear(db);
                ref.invalidate(rommDownloadHistoryProvider);
              }
            },
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.download_done_outlined,
                    size: 56,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                  ),
                  const SizedBox(height: 12),
                  const Text('No downloads yet'),
                  const SizedBox(height: 4),
                  Text(
                    'ROMs you download will be listed here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: records.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 60),
            itemBuilder: (context, index) {
              final record = records[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.tealPrimary.withAlpha(18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.videogame_asset_outlined,
                    size: 20,
                    color: AppColors.tealPrimary,
                  ),
                ),
                title: Text(record.romName,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    record.fileName,
                    if (record.sizeBytes > 0)
                      ByteFormatter.format(record.sizeBytes),
                    DateFormat('d MMM yyyy, HH:mm').format(record.savedAt),
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Remove from history',
                  onPressed: () async {
                    await RommDownloadHistory.removeAt(db, index);
                    ref.invalidate(rommDownloadHistoryProvider);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
