import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/tautulli_history.dart';
import '../providers/tautulli_providers.dart';

class TautulliHistoryScreen extends ConsumerWidget {
  const TautulliHistoryScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(tautulliHistoryProvider(instance));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (history) {
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async =>
              ref.invalidate(tautulliHistoryProvider(instance)),
          child: ListView.separated(
            itemCount: history.items.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = history.items[index];
              final dateStr = item.stoppedAt != null
                  ? DateFormat.MMMd().add_Hm().format(item.stoppedAt!)
                  : 'Unknown';

              final displayTitle = _buildDisplayTitle(item);
              return ListTile(
                onTap: () => _showHistoryDetail(context, item),
                title: Text(
                  displayTitle,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${item.friendlyName ?? item.user ?? 'Unknown'} • $dateStr',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: Text(
                  '${item.percentComplete}%',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: item.percentComplete >= 90
                            ? AppColors.statusOnline
                            : AppColors.statusWarning,
                      ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _buildDisplayTitle(TautulliHistoryItem item) {
    final title = item.title ?? 'Unknown';
    if (item.grandparentTitle != null && item.grandparentTitle!.isNotEmpty) {
      return '${item.grandparentTitle} – $title';
    }
    return title;
  }

  void _showHistoryDetail(BuildContext context, TautulliHistoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _HistoryDetailSheet(item: item),
    );
  }
}

class _HistoryDetailSheet extends StatelessWidget {
  const _HistoryDetailSheet({required this.item});
  final TautulliHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stoppedStr = item.stoppedAt != null
        ? DateFormat.yMMMd().add_Hm().format(item.stoppedAt!)
        : '—';
    final durationStr = _formatDuration(item.duration);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (item.grandparentTitle != null &&
                item.grandparentTitle!.isNotEmpty)
              Text(
                item.grandparentTitle!,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            Text(
              item.title ?? 'Unknown',
              style: item.grandparentTitle != null
                  ? theme.textTheme.bodyMedium
                  : theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            if (item.mediaType != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.tealPrimary.withAlpha(20),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.mediaType!,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.tealPrimary),
                ),
              ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: item.percentComplete / 100,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
              backgroundColor: AppColors.tealPrimary.withAlpha(20),
              color: AppColors.tealPrimary,
            ),
            const SizedBox(height: 4),
            Text('${item.percentComplete}% watched',
                style: theme.textTheme.bodySmall),
            const Divider(height: 24),
            _Row(label: 'User',
                value: item.friendlyName ?? item.user ?? '—'),
            _Row(label: 'Watched', value: stoppedStr),
            _Row(label: 'Duration', value: durationStr),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '${h}h ${m}m ${s}s';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
