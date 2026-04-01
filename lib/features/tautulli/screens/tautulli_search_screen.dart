import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../api/models/tautulli_media_item.dart';
import '../api/tautulli_api.dart';
import '../providers/tautulli_providers.dart';

class TautulliSearchScreen extends ConsumerStatefulWidget {
  const TautulliSearchScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<TautulliSearchScreen> createState() =>
      _TautulliSearchScreenState();
}

class _TautulliSearchScreenState extends ConsumerState<TautulliSearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    ref
        .read(tautulliSearchQueryProvider(widget.instance.id).notifier)
        .state = v;
  }

  void _clear() {
    _controller.clear();
    ref
        .read(tautulliSearchQueryProvider(widget.instance.id).notifier)
        .state = '';
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(tautulliSearchQueryProvider(widget.instance.id));
    final resultsAsync = ref.watch(tautulliLibrarySearchProvider(
        (instance: widget.instance, query: query)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search Plex library…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: _clear,
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
          ),
        ),
        Expanded(child: _ResultsBody(
          query: query,
          resultsAsync: resultsAsync,
          instance: widget.instance,
        )),
      ],
    );
  }
}

// ─── Results body ─────────────────────────────────────────────────────────────

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    required this.query,
    required this.resultsAsync,
    required this.instance,
  });

  final String query;
  final AsyncValue<Map<String, List<TautulliMediaItem>>> resultsAsync;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('Search movies, shows, episodes, music…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (grouped) {
        if (grouped.isEmpty) {
          return Center(
            child: Text('No results for "$query"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          );
        }

        // Display order
        const order = ['movie', 'show', 'season', 'episode', 'artist', 'album', 'track'];
        final sections = order
            .where((k) => grouped.containsKey(k))
            .map((k) => (k, grouped[k]!))
            .toList();
        // Append any unexpected keys
        for (final entry in grouped.entries) {
          if (!order.contains(entry.key)) {
            sections.add((entry.key, entry.value));
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final (type, items) = sections[index];
            return _SectionGroup(
              type: type,
              items: items,
              instance: instance,
            );
          },
        );
      },
    );
  }
}

// ─── Section group ────────────────────────────────────────────────────────────

class _SectionGroup extends StatelessWidget {
  const _SectionGroup({
    required this.type,
    required this.items,
    required this.instance,
  });

  final String type;
  final List<TautulliMediaItem> items;
  final Instance instance;

  String get _sectionLabel => switch (type) {
        'movie' => 'Movies',
        'show' => 'TV Shows',
        'season' => 'Seasons',
        'episode' => 'Episodes',
        'artist' => 'Artists',
        'album' => 'Albums',
        'track' => 'Tracks',
        _ => type[0].toUpperCase() + type.substring(1),
      };

  IconData get _sectionIcon => switch (type) {
        'movie' => Icons.movie_outlined,
        'show' => Icons.tv,
        'season' => Icons.playlist_play,
        'episode' => Icons.play_circle_outline,
        'artist' => Icons.person_outline,
        'album' => Icons.album_outlined,
        'track' => Icons.music_note_outlined,
        _ => Icons.folder_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final api = TautulliApi.fromInstance(instance);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(_sectionIcon,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(_sectionLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${items.length}',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onPrimaryContainer)),
              ),
            ],
          ),
        ),
        ...items.map((item) => _ResultTile(item: item, api: api)),
        const Divider(height: 1),
      ],
    );
  }
}

// ─── Result tile ──────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.item, required this.api});

  final TautulliMediaItem item;
  final TautulliApi api;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbUrl = api.thumbUrl(item.thumb ?? '');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: item.thumb != null && item.thumb!.isNotEmpty
            ? Image.network(
                thumbUrl,
                width: 40,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (context, error, _) => _PosterPlaceholder(item.mediaType),
              )
            : _PosterPlaceholder(item.mediaType),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium,
      ),
      subtitle: Text(
        _subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  String get _subtitle {
    final parts = <String>[];
    if (item.grandparentTitle != null) parts.add(item.grandparentTitle!);
    if (item.parentTitle != null &&
        item.parentTitle != item.grandparentTitle) {
      parts.add(item.parentTitle!);
    }
    if (item.year != null) parts.add(item.year!);
    return parts.join(' · ');
  }
}

// ─── Poster placeholder ───────────────────────────────────────────────────────

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder(this.mediaType);
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    final icon = switch (mediaType) {
      'movie' => Icons.movie_outlined,
      'show' || 'season' || 'episode' => Icons.tv,
      'artist' || 'album' || 'track' => Icons.music_note_outlined,
      _ => Icons.image_outlined,
    };
    return Container(
      width: 40,
      height: 58,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(icon,
          size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
