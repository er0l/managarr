import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/tautulli_library.dart';
import '../api/models/tautulli_media_item.dart';
import '../api/tautulli_api.dart';
import '../providers/tautulli_providers.dart';
import 'tautulli_library_detail_screen.dart';

class TautulliLibrariesScreen extends ConsumerStatefulWidget {
  const TautulliLibrariesScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<TautulliLibrariesScreen> createState() =>
      _TautulliLibrariesScreenState();
}

class _TautulliLibrariesScreenState
    extends ConsumerState<TautulliLibrariesScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  // null = no active search; AsyncLoading / AsyncData / AsyncError
  AsyncValue<Map<String, List<TautulliMediaItem>>>? _searchResult;
  List<TautulliLibrary>? _libraries;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  String get _query => _searchController.text.trim();

  void _onChanged(String _) {
    _debounce?.cancel();
    final q = _query;
    if (q.isEmpty) {
      setState(() => _searchResult = null);
      return;
    }
    // Show loading immediately so the user gets feedback
    setState(() => _searchResult = const AsyncValue.loading());
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    if (!mounted || q != _query) return;
    try {
      final api = ref.read(tautulliApiProvider(widget.instance));
      final result = await api.librarySearch(q);
      if (mounted && q == _query) {
        setState(() => _searchResult = AsyncValue.data(result));
      }
    } catch (e, st) {
      if (mounted && q == _query) {
        setState(() => _searchResult = AsyncValue.error(e, st));
      }
    }
  }

  void _clear() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() => _searchResult = null);
  }

  @override
  Widget build(BuildContext context) {
    final librariesAsync = ref.watch(tautulliLibrariesProvider(widget.instance));
    // Keep a resolved copy so search tiles can navigate
    librariesAsync.whenData((libs) => _libraries = libs);

    final searching = _searchResult != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Plex library…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: searching
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
            onSubmitted: (_) {
              _debounce?.cancel();
              final q = _query;
              if (q.isNotEmpty) _search(q);
            },
          ),
        ),
        Expanded(
          child: searching
              ? _SearchResults(
                  query: _query,
                  result: _searchResult!,
                  libraries: _libraries,
                  instance: widget.instance,
                )
              : _LibraryList(
                  librariesAsync: librariesAsync,
                  instance: widget.instance,
                  ref: ref,
                ),
        ),
      ],
    );
  }
}

// ─── Library list ─────────────────────────────────────────────────────────────

class _LibraryList extends StatelessWidget {
  const _LibraryList({
    required this.librariesAsync,
    required this.instance,
    required this.ref,
  });

  final AsyncValue librariesAsync;
  final Instance instance;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return librariesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (libraries) {
        final libs = libraries as List<TautulliLibrary>;
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async =>
              ref.invalidate(tautulliLibrariesProvider(instance)),
          child: ListView.separated(
            itemCount: libs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final lib = libs[index];
              return ListTile(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TautulliLibraryDetailScreen(
                      instance: instance,
                      library: lib,
                    ),
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.tealPrimary.withAlpha(30),
                  child: Icon(
                    _getLibraryIcon(lib.sectionType),
                    color: AppColors.tealPrimary,
                    size: 20,
                  ),
                ),
                title: Text(
                  lib.sectionName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  '${lib.count} items',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right,
                    size: 20, color: AppColors.textSecondary),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getLibraryIcon(String type) {
    return switch (type.toLowerCase()) {
      'movie' => Icons.movie_outlined,
      'show' => Icons.tv_outlined,
      'artist' => Icons.music_note_outlined,
      'photo' => Icons.photo_outlined,
      _ => Icons.folder_outlined,
    };
  }
}

// ─── Search results ────────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.result,
    required this.libraries,
    required this.instance,
  });

  final String query;
  final AsyncValue<Map<String, List<TautulliMediaItem>>> result;
  final List<TautulliLibrary>? libraries;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return result.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Search error: $e',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.statusOffline)),
        ),
      ),
      data: (grouped) {
        if (grouped.isEmpty) {
          return Center(
            child: Text(
              'No results for "$query"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }

        const order = [
          'movie', 'show', 'season', 'episode', 'artist', 'album', 'track'
        ];
        final sections = <(String, List<TautulliMediaItem>)>[];
        for (final k in order) {
          if (grouped.containsKey(k)) sections.add((k, grouped[k]!));
        }
        for (final entry in grouped.entries) {
          if (!order.contains(entry.key)) sections.add((entry.key, entry.value));
        }

        final api = TautulliApi.fromInstance(instance);

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: sections.length,
          itemBuilder: (context, index) {
            final (type, items) = sections[index];
            return _SectionGroup(
              type: type,
              items: items,
              api: api,
              instance: instance,
              libraries: libraries,
            );
          },
        );
      },
    );
  }
}

// ─── Section group ─────────────────────────────────────────────────────────────

class _SectionGroup extends StatelessWidget {
  const _SectionGroup({
    required this.type,
    required this.items,
    required this.api,
    required this.instance,
    required this.libraries,
  });

  final String type;
  final List<TautulliMediaItem> items;
  final TautulliApi api;
  final Instance instance;
  final List<TautulliLibrary>? libraries;

  String get _label => switch (type) {
        'movie' => 'Movies',
        'show' => 'TV Shows',
        'season' => 'Seasons',
        'episode' => 'Episodes',
        'artist' => 'Artists',
        'album' => 'Albums',
        'track' => 'Tracks',
        _ => type[0].toUpperCase() + type.substring(1),
      };

  IconData get _icon => switch (type) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Icon(_icon, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(_label,
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
        ...items.map((item) => _ResultTile(
              item: item,
              api: api,
              instance: instance,
              libraries: libraries,
            )),
        const Divider(height: 1),
      ],
    );
  }
}

// ─── Result tile ──────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.item,
    required this.api,
    required this.instance,
    required this.libraries,
  });

  final TautulliMediaItem item;
  final TautulliApi api;
  final Instance instance;
  final List<TautulliLibrary>? libraries;

  void _onTap(BuildContext context) {
    if (item.sectionId == null) return;
    final library =
        libraries?.where((l) => l.sectionId == item.sectionId).firstOrNull ??
            TautulliLibrary(
              sectionId: item.sectionId!,
              sectionName: item.libraryName ?? 'Library',
              sectionType: '',
              count: 0,
            );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TautulliLibraryDetailScreen(
          instance: instance,
          library: library,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final thumbUrl = api.thumbUrl(item.thumb ?? '');

    final parts = <String>[
      if (item.grandparentTitle != null) item.grandparentTitle!,
      if (item.parentTitle != null && item.parentTitle != item.grandparentTitle)
        item.parentTitle!,
      if (item.libraryName != null)
        item.libraryName!
      else if (item.year != null)
        item.year!,
    ];

    final canTap = item.sectionId != null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: canTap ? () => _onTap(context) : null,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: item.thumb != null && item.thumb!.isNotEmpty
            ? Image.network(
                thumbUrl,
                width: 40,
                height: 58,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder,
              )
            : _placeholder,
      ),
      title: Text(item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium),
      subtitle: parts.isNotEmpty
          ? Text(parts.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          : null,
      trailing: canTap
          ? const Icon(Icons.chevron_right,
              size: 18, color: AppColors.textSecondary)
          : null,
    );
  }

  Widget get _placeholder => Container(
        width: 40,
        height: 58,
        color: Colors.grey.withAlpha(40),
        child: const Icon(Icons.image_outlined, size: 18, color: Colors.grey),
      );
}
