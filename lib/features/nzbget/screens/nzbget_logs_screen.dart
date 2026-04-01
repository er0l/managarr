import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/nzbget_providers.dart';

class NzbgetLogsScreen extends ConsumerWidget {
  const NzbgetLogsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(nzbgetLogsProvider(instance));

    return logsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (logs) {
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(nzbgetLogsProvider(instance)),
          child: ListView.separated(
            itemCount: logs.items.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = logs.items[index];
              final timeStr = item.timestamp != null
                  ? DateFormat.Hm().format(item.timestamp!)
                  : '--:--';

              Color kindColor = AppColors.textSecondary;
              if (item.kind == 'ERROR') kindColor = AppColors.statusOffline;
              if (item.kind == 'WARNING') kindColor = AppColors.statusWarning;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.tealPrimary,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: kindColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.kind,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: kindColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.text,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
