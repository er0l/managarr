import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/search_result.dart';
import '../providers/seer_providers.dart';
import '../widgets/media_card.dart';
import 'seer_media_detail_screen.dart';

class SeerDiscoverScreen extends ConsumerStatefulWidget {
  const SeerDiscoverScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SeerDiscoverScreen> createState() =>
      _SeerDiscoverScreenState();
}

class _SeerDiscoverScreenState extends ConsumerState<SeerDiscoverScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(
          seerDiscoverSearchQueryProvider(widget.instance.id));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    ref
        .read(seerDiscoverSearchQueryProvider(widget.instance.id).notifier)
        .state = '';
  }

  void _refresh() {
    ref.invalidate(seerDiscoverMoviesProvider(widget.instance));
    ref.invalidate(seerDiscoverTvProvider(widget.instance));
    final q = ref
        .read(seerDiscoverSearchQueryProvider(widget.instance.id))
        .trim();
    if (q.isNotEmpty) {
      ref.invalidate(
          seerSearchProvider((instance: widget.instance, query: q)));
    }
  }

  void _showSortSheet() {
    final current =
        ref.read(seerDiscoverSortProvider(widget.instance.id));

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Text('Sort by',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: RadioGroup<SeerDiscoverSort>(
                groupValue: current,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(seerDiscoverSortProvider(
                                widget.instance.id)
                            .notifier)
                        .state = val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: SeerDiscoverSort.values
                      .map((opt) => RadioListTile<SeerDiscoverSort>(
                            title: Text(opt.label),
                            value: opt,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMode =
        ref.watch(seerDisplayModeProvider(widget.instance.id));
    final query =
        ref.watch(seerDiscoverSearchQueryProvider(widget.instance.id));
    final sort = ref.watch(seerDiscoverSortProvider(widget.instance.id));
    final moviesAsync =
        ref.watch(seerFilteredDiscoverMoviesProvider(widget.instance));
    final tvAsync =
        ref.watch(seerFilteredDiscoverTvProvider(widget.instance));

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Shows'),
          ],
        ),
        // ── Search & sort bar ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.pageHorizontal,
            Spacing.s8,
            Spacing.pageHorizontal,
            Spacing.s4,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search movies & shows…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: _clearSearch,
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => ref
                      .read(seerDiscoverSearchQueryProvider(
                              widget.instance.id)
                          .notifier)
                      .state = v,
                ),
              ),
              const SizedBox(width: Spacing.s8),
              _SortButton(
                isActive: sort != SeerDiscoverSort.defaultOrder,
                onTap: _showSortSheet,
              ),
            ],
          ),
        ),
        // ── Tab content ────────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _DiscoverView(
                instance: widget.instance,
                resultsAsync: moviesAsync,
                displayMode: displayMode,
                query: query,
                onRefresh: _refresh,
              ),
              _DiscoverView(
                instance: widget.instance,
                resultsAsync: tvAsync,
                displayMode: displayMode,
                query: query,
                onRefresh: _refresh,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _SortButton extends StatelessWidget {
  const _SortButton({required this.isActive, required this.onTap});
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      onPressed: onTap,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor:
            isActive ? colorScheme.primaryContainer : null,
        foregroundColor:
            isActive ? colorScheme.onPrimaryContainer : null,
      ),
      icon: const Icon(Icons.sort),
    );
  }
}

// ---------------------------------------------------------------------------

class _DiscoverView extends StatelessWidget {
  const _DiscoverView({
    required this.instance,
    required this.resultsAsync,
    required this.displayMode,
    required this.query,
    required this.onRefresh,
  });

  final Instance instance;
  final AsyncValue<List<SeerSearchResult>> resultsAsync;
  final DisplayMode displayMode;
  final String query;
  final VoidCallback onRefresh;

  void _openDetail(BuildContext context, SeerSearchResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeerMediaDetailScreen(
          instance: instance,
          tmdbId: result.id,
          mediaType: result.mediaType,
          initialTitle: result.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return resultsAsync.when(
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
              onPressed: onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(
              query.isNotEmpty
                  ? 'No results for "$query"'
                  : 'Nothing to show',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          );
        }
        return RefreshIndicator(
          color: AppColors.tealPrimary,
          onRefresh: () async => onRefresh(),
          child: displayMode == DisplayMode.grid
              ? _DiscoverGrid(
                  results: results,
                  onTap: (r) => _openDetail(context, r),
                )
              : _DiscoverList(
                  results: results,
                  onTap: (r) => _openDetail(context, r),
                ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _DiscoverGrid extends StatelessWidget {
  const _DiscoverGrid({required this.results, required this.onTap});
  final List<SeerSearchResult> results;
  final void Function(SeerSearchResult) onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.s8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            MediaQuery.of(context).size.width >= 600 ? 3 : 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: Spacing.s8,
        mainAxisSpacing: Spacing.s8,
      ),
      itemCount: results.length,
      itemBuilder: (ctx, i) => MediaCard(
        result: results[i],
        onTap: () => onTap(results[i]),
      ),
    );
  }
}

class _DiscoverList extends StatelessWidget {
  const _DiscoverList({required this.results, required this.onTap});
  final List<SeerSearchResult> results;
  final void Function(SeerSearchResult) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      itemCount: results.length,
      separatorBuilder: (_, i) => const Divider(height: 1),
      itemBuilder: (ctx, i) => _MediaTile(
        result: results[i],
        onTap: () => onTap(results[i]),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({required this.result, required this.onTap});
  final SeerSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = result.posterUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: Spacing.pageHorizontal,
        vertical: 4,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 44,
          height: 64,
          child: posterUrl != null
              ? Image.network(
                  posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, e, s) => _PosterPlaceholder(
                    mediaType: result.mediaType,
                  ),
                )
              : _PosterPlaceholder(mediaType: result.mediaType),
        ),
      ),
      title: Text(
        result.title,
        style: theme.textTheme.bodyLarge
            ?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (result.year.isNotEmpty) result.year,
          result.mediaType == 'movie' ? 'Movie' : 'TV Show',
          if (result.voteAverage > 0)
            '★ ${result.voteAverage.toStringAsFixed(1)}',
        ].join(' · '),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: AppColors.textSecondary),
      ),
      onTap: onTap,
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.mediaType});
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Icon(
        mediaType == 'movie' ? Icons.movie_outlined : Icons.tv_outlined,
        color: Colors.white24,
        size: 24,
      ),
    );
  }
}
