import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/tautulli_providers.dart';

class TautulliRecentlyAddedScreen extends ConsumerStatefulWidget {
  const TautulliRecentlyAddedScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<TautulliRecentlyAddedScreen> createState() =>
      _TautulliRecentlyAddedScreenState();
}

class _TautulliRecentlyAddedScreenState
    extends ConsumerState<TautulliRecentlyAddedScreen> {
  String? _mediaTypeFilter; // null = all, 'movie', 'show', 'artist'

  @override
  Widget build(BuildContext context) {
    final itemsAsync =
        ref.watch(tautulliRecentlyAddedProvider(widget.instance));
    final api = ref.read(tautulliApiProvider(widget.instance));

    return Column(
      children: [
        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _mediaTypeFilter == null,
                onTap: () => setState(() => _mediaTypeFilter = null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Movies',
                selected: _mediaTypeFilter == 'movie',
                onTap: () => setState(() => _mediaTypeFilter = 'movie'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'TV Shows',
                selected: _mediaTypeFilter == 'episode',
                onTap: () => setState(() => _mediaTypeFilter = 'episode'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Music',
                selected: _mediaTypeFilter == 'track',
                onTap: () => setState(() => _mediaTypeFilter = 'track'),
              ),
            ],
          ),
        ),
        Expanded(
          child: itemsAsync.when(
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
                    onPressed: () => ref.invalidate(
                        tautulliRecentlyAddedProvider(widget.instance)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (items) {
              final filtered = _mediaTypeFilter == null
                  ? items
                  : items
                      .where((i) => i.mediaType == _mediaTypeFilter)
                      .toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('Nothing recently added'));
              }

              return RefreshIndicator(
                color: AppColors.tealPrimary,
                onRefresh: () async => ref.invalidate(
                    tautulliRecentlyAddedProvider(widget.instance)),
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, i) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    final thumbUrl =
                        item.thumb != null && item.thumb!.isNotEmpty
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
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.tealPrimary
              : AppColors.tealPrimary.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? Colors.white : AppColors.tealPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
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
