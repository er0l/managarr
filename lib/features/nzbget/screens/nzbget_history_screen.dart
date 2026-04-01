import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/config/byte_formatter.dart';
import '../api/nzbget_api.dart';
import '../providers/nzbget_providers.dart';

class NzbgetHistoryScreen extends ConsumerWidget {
  const NzbgetHistoryScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(nzbgetHistoryProvider(instance));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (history) {
        final api = NzbgetApi.fromInstance(instance);

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(nzbgetHistoryProvider(instance)),
          child: ListView.separated(
            itemCount: history.items.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = history.items[index];
              final dateStr = item.completedAt != null
                  ? DateFormat.yMMMd().add_Hm().format(item.completedAt!)
                  : 'Unknown date';

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
                    const SizedBox(height: 4),
                    Text(
                      '$dateStr • ${item.category}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${ByteFormatter.format(item.fileSize)} • ${item.status}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: item.status.toLowerCase() == 'success'
                                ? AppColors.statusOnline
                                : AppColors.statusWarning,
                          ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () async {
                    final confirmed = await _confirmDelete(context);
                    if (confirmed) {
                      await api.deleteHistory(item.id);
                      ref.invalidate(nzbgetHistoryProvider(instance));
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete History Entry'),
            content: const Text('Are you sure you want to delete this entry from history?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }
}
