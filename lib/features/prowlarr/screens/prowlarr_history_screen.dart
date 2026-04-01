import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/prowlarr_providers.dart';

class ProwlarrHistoryScreen extends ConsumerWidget {
  const ProwlarrHistoryScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(prowlarrHistoryProvider(instance));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            Text('$e'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(prowlarrHistoryProvider(instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No history found'));
        }
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async =>
              ref.invalidate(prowlarrHistoryProvider(instance)),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final dateStr =
                  DateFormat.MMMd().add_Hm().format(item.date.toLocal());

              return ListTile(
                leading: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: (item.successful
                            ? AppColors.statusOnline
                            : AppColors.statusOffline)
                        .withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    item.successful ? Icons.check : Icons.close,
                    size: 16,
                    color: item.successful
                        ? AppColors.statusOnline
                        : AppColors.statusOffline,
                  ),
                ),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  '${item.indexerName} • $dateStr',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: item.categories.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.tealPrimary.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.categories.first,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.tealPrimary),
                        ),
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}
