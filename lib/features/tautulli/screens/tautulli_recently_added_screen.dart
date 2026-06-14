import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/tautulli_providers.dart';

class TautulliRecentlyAddedScreen extends ConsumerWidget {
  const TautulliRecentlyAddedScreen({
    super.key,
    required this.instance,
    this.mediaTypeFilter,
  });

  final Instance instance;
  // null = all, 'movie', 'episode', 'track' — controlled by parent (home screen)
  final String? mediaTypeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(tautulliRecentlyAddedProvider(instance));
    final api = ref.read(tautulliApiProvider(instance));

    return itemsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            const Text('Failed to load'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  ref.invalidate(tautulliRecentlyAddedProvider(instance)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (items) {
        final filtered = mediaTypeFilter == null
            ? items
            : items.where((i) => i.mediaType == mediaTypeFilter).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('Nothing recently added'));
        }

        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async =>
              ref.invalidate(tautulliRecentlyAddedProvider(instance)),
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: filtered.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final item = filtered[i];
              final thumbUrl = item.thumb != null && item.thumb!.isNotEmpty
                  ? api.thumbUrl(item.thumb!)
                  : null;
              final dateStr = item.addedAtDate != null
                  ? DateFormat.MMMd().format(item.addedAtDate!)
                  : '';

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    width: 40,
                    height: 60,
                    child: thumbUrl != null
                        ? Image.network(
                            thumbUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                _TypeIcon(mediaType: item.mediaType),
                          )
                        : _TypeIcon(mediaType: item.mediaType),
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
                  item.subtitle,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
                trailing: Text(
                  dateStr,
                  style: Theme.of(ctx)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.mediaType});
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Icon(
        mediaType == 'movie'
            ? Icons.movie_outlined
            : mediaType == 'episode'
                ? Icons.tv_outlined
                : Icons.music_note_outlined,
        color: Colors.white24,
        size: 20,
      ),
    );
  }
}
