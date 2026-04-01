import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/tautulli_library.dart';
import '../providers/tautulli_providers.dart';

class TautulliLibraryDetailScreen extends ConsumerWidget {
  const TautulliLibraryDetailScreen({
    super.key,
    required this.instance,
    required this.library,
  });

  final Instance instance;
  final TautulliLibrary library;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(
      tautulliLibraryMediaProvider(
          (instance: instance, sectionId: library.sectionId)),
    );
    final api = ref.read(tautulliApiProvider(instance));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Text(
          library.sectionName,
          style: const TextStyle(
            color: AppColors.textOnPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Library stats header
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.tealPrimary.withAlpha(10),
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                    label: _itemLabel(library.sectionType),
                    value: '${library.count}',
                    icon: _typeIcon(library.sectionType),
                  ),
                  if ((library.parentCount ?? 0) > 0)
                    _StatChip(
                      label: _parentLabel(library.sectionType),
                      value: '${library.parentCount}',
                      icon: Icons.folder_outlined,
                    ),
                  if ((library.childCount ?? 0) > 0)
                    _StatChip(
                      label: _childLabel(library.sectionType),
                      value: '${library.childCount}',
                      icon: Icons.description_outlined,
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Recently Added',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.tealPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          mediaAsync.when(
            loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverToBoxAdapter(
                child: Center(child: Text('Error: $e'))),
            data: (items) {
              if (items.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No items found'),
                    ),
                  ),
                );
              }
              return SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = items[i];
                  final thumbUrl = item.thumb != null && item.thumb!.isNotEmpty
                      ? api.thumbUrl(item.thumb!)
                      : null;
                  final dateStr = item.addedAtDate != null
                      ? DateFormat.yMMMd().format(item.addedAtDate!)
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
                                    _PlaceholderPoster(
                                        mediaType: item.mediaType),
                              )
                            : _PlaceholderPoster(mediaType: item.mediaType),
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
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  String _itemLabel(String type) {
    switch (type.toLowerCase()) {
      case 'movie': return 'Movies';
      case 'show': return 'Shows';
      case 'artist': return 'Artists';
      default: return 'Items';
    }
  }

  String _parentLabel(String type) {
    switch (type.toLowerCase()) {
      case 'show': return 'Seasons';
      case 'artist': return 'Albums';
      default: return 'Parents';
    }
  }

  String _childLabel(String type) {
    switch (type.toLowerCase()) {
      case 'show': return 'Episodes';
      case 'artist': return 'Tracks';
      default: return 'Children';
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'movie': return Icons.movie_outlined;
      case 'show': return Icons.tv_outlined;
      case 'artist': return Icons.music_note_outlined;
      case 'photo': return Icons.photo_outlined;
      default: return Icons.folder_outlined;
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.tealPrimary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _PlaceholderPoster extends StatelessWidget {
  const _PlaceholderPoster({required this.mediaType});
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
