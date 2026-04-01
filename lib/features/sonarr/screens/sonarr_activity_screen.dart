import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/sonarr_providers.dart';

class SonarrActivityScreen extends ConsumerWidget {
  const SonarrActivityScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sonarrHistoryProvider(instance));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (history) {
        if (history.records.isEmpty) {
          return const Center(child: Text('No activity history found'));
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(sonarrHistoryProvider(instance)),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: Spacing.s8),
            itemCount: history.records.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final record = history.records[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.pageHorizontal,
                  vertical: 4,
                ),
                leading: _ActivityIcon(eventType: record.eventType),
                title: Text(
                  record.sourceTitle ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  DateFormat('MMM d, y • HH:mm').format(record.date.toLocal()),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                trailing: Text(
                  record.eventType.replaceAll(RegExp(r'(?=[A-Z])'), ' ').trim(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
}

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.eventType});
  final String eventType;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (eventType.toLowerCase()) {
      'grabbed' => (Icons.cloud_download_outlined, Colors.blue),
      'downloadfolderimported' || 'seriesfileimported' => (Icons.file_download_done, Colors.green),
      'seriesfiledeleted' || 'episodefiledeleted' => (Icons.delete_outline, Colors.red),
      'downloadfailed' => (Icons.error_outline, Colors.orange),
      _ => (Icons.history, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
