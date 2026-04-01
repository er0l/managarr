import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/lidarr_providers.dart';

class LidarrMissingAlbumsScreen extends ConsumerWidget {
  const LidarrMissingAlbumsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missingAsync =
        ref.watch(lidarrWantedMissingProvider(instance));

    return missingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off,
                  size: 48, color: AppColors.statusOffline),
              const SizedBox(height: Spacing.s16),
              Text('Failed to load missing albums',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: Spacing.s24),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(lidarrWantedMissingProvider(instance)),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.tealPrimary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: const StadiumBorder()),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (albums) {
        if (albums.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 64, color: AppColors.statusOnline),
                const SizedBox(height: Spacing.s16),
                Text('No missing albums!',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: Spacing.s8),
                Text('All monitored albums are downloaded',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async =>
              ref.invalidate(lidarrWantedMissingProvider(instance)),
          child: ListView.separated(
            padding: const EdgeInsets.only(
                top: Spacing.s8, bottom: Spacing.s24),
            itemCount: albums.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final album = albums[index];
              final releaseDate = album.releaseDate;
              String? dateStr;
              if (releaseDate != null) {
                dateStr = DateFormat.yMMMd().format(releaseDate);
              }
              final coverUrl = album.coverUrl;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: Spacing.pageHorizontal, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: coverUrl != null
                        ? Image.network(coverUrl, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.tealDark,
                            alignment: Alignment.center,
                            child: const Icon(Icons.album,
                                color: Colors.white54, size: 24),
                          ),
                  ),
                ),
                title: Text(
                  album.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: dateStr != null
                    ? Text(dateStr,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary))
                    : null,
                trailing: album.monitored
                    ? const Icon(Icons.bookmark,
                        size: 16, color: AppColors.tealPrimary)
                    : const Icon(Icons.bookmark_border,
                        size: 16, color: AppColors.textSecondary),
              );
            },
          ),
        );
      },
    );
  }
}
