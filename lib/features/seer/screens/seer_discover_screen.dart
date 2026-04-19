import 'dart:async';

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

// ---------------------------------------------------------------------------
// Root screen widget
// ---------------------------------------------------------------------------

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
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Restore any previously typed query into the text field.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text =
          ref.read(seerDiscoverSearchQueryProvider(widget.instance.id));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(seerDiscoverSearchQueryProvider(widget.instance.id).notifier)
          .state = v.trim();
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    ref
        .read(seerDiscoverSearchQueryProvider(widget.instance.id).notifier)
        .state = '';
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
    final query =
        ref.watch(seerDiscoverSearchQueryProvider(widget.instance.id));
    final sort = ref.watch(seerDiscoverSortProvider(widget.instance.id));

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
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: Spacing.s8),
              _SortButton(
                isActive: sort != SeerDiscoverSort.popularityDesc,
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
              _PaginatedTab(
                instance: widget.instance,
                mediaType: 'movie',
              ),
              _PaginatedTab(
                instance: widget.instance,
                mediaType: 'tv',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sort button
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
// Paginated tab — self-contained, reacts to query/sort changes via ref.listen
// ---------------------------------------------------------------------------

class _PaginatedTab extends ConsumerStatefulWidget {
  const _PaginatedTab({
    required this.instance,
    required this.mediaType,
  });

  final Instance instance;
  /// 'movie' or 'tv'
  final String mediaType;

  @override
  ConsumerState<_PaginatedTab> createState() => _PaginatedTabState();
}

class _PaginatedTabState extends ConsumerState<_PaginatedTab> {
  final _scrollController = ScrollController();

  List<SeerSearchResult> _items = [];
  int _page = 1;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  /// Monotonically-increasing counter.  Each reset bumps it; in-flight
  /// responses whose generation doesn't match the current one are discarded,
  /// preventing stale results from landing after a sort/query change.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) { if (mounted) _doLoad(reset: true); });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _doLoad(reset: false);
    }
  }

  // ── Load logic ────────────────────────────────────────────────────────────

  Future<void> _doLoad({required bool reset}) async {
    if (reset) {
      if (_isLoading) {
        // A reset is already in progress; discard current in-flight via
        // generation bump and start fresh.
        _generation++;
      }
    } else {
      if (_isLoadingMore || !_hasMore || _isLoading) return;
    }

    final page = reset ? 1 : _page;
    final generation = reset ? ++_generation : _generation;
    final query =
        ref.read(seerDiscoverSearchQueryProvider(widget.instance.id)).trim();
    final sort = ref.read(seerDiscoverSortProvider(widget.instance.id));
    final api = ref.read(seerApiProvider(widget.instance));

    if (mounted) {
      setState(() {
        if (reset) {
          _items = [];
          _page = 1;
          _hasMore = true;
          _error = null;
          _isLoading = true;
        } else {
          _isLoadingMore = true;
        }
      });
    }

    try {
      final List<SeerSearchResult> pageItems;
      final bool hasMore;

      if (query.isEmpty) {
        // ── Discover mode: type-specific endpoint, server-side sort ──────
        final results = widget.mediaType == 'movie'
            ? await api.getDiscoverMovies(page: page, sortBy: sort.movieSort)
            : await api.getDiscoverTv(page: page, sortBy: sort.tvSort);
        pageItems = results;
        // TMDB returns exactly 20 per page; fewer → last page.
        hasMore = results.length >= 20;
      } else {
        // ── Search mode: mixed results, filter by mediaType client-side ──
        // Base _hasMore on the raw (unfiltered) page length so we keep
        // fetching even when some pages happen to contain no items of the
        // desired type.
        final allResults = await api.search(query, page: page);
        pageItems = allResults
            .where((r) => r.mediaType == widget.mediaType)
            .toList();
        hasMore = allResults.length >= 20;
      }

      // Discard stale results if a newer reset started while we were awaiting.
      if (!mounted || generation != _generation) return;

      setState(() {
        _items = reset ? pageItems : [..._items, ...pageItems];
        _page = page + 1;
        _hasMore = hasMore;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        if (reset) _error = '$e';
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void _openDetail(SeerSearchResult result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SeerMediaDetailScreen(
          instance: widget.instance,
          tmdbId: result.id,
          mediaType: result.mediaType,
          initialTitle: result.title,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final displayMode =
        ref.watch(seerDisplayModeProvider(widget.instance.id));
    final query =
        ref.watch(seerDiscoverSearchQueryProvider(widget.instance.id)).trim();

    // React to query changes (debounced in parent) → reset + reload.
    ref.listen(seerDiscoverSearchQueryProvider(widget.instance.id),
        (prev, next) {
      if (prev != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _doLoad(reset: true);
        });
      }
    });

    // React to sort changes → reset + reload.
    ref.listen(seerDiscoverSortProvider(widget.instance.id), (prev, next) {
      if (prev != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _doLoad(reset: true);
        });
      }
    });

    // ── Initial / full-page load spinner ──────────────────────────────
    if (_isLoading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // ── Error with no cached items ────────────────────────────────────
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            const Text('Failed to load'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _doLoad(reset: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // ── Empty state ───────────────────────────────────────────────────
    if (!_isLoading && _items.isEmpty) {
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

    // ── Content ───────────────────────────────────────────────────────
    return RefreshIndicator(
      color: AppColors.tealPrimary,
      onRefresh: () async => _doLoad(reset: true),
      child: displayMode == DisplayMode.grid
          ? _buildGrid()
          : _buildList(),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacing.s8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:
            MediaQuery.of(context).size.width >= 600 ? 3 : 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: Spacing.s8,
        mainAxisSpacing: Spacing.s8,
      ),
      itemCount: _items.length + (_isLoadingMore ? 2 : 0),
      itemBuilder: (ctx, i) {
        if (i >= _items.length) {
          return const Card(
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return MediaCard(
          result: _items[i],
          onTap: () => _openDetail(_items[i]),
        );
      },
    );
  }

  Widget _buildList() {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      itemCount: _items.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        if (i == _items.length) {
          return const Padding(
            padding: EdgeInsets.all(Spacing.s16),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.tealPrimary,
              ),
            ),
          );
        }
        return _MediaTile(
          result: _items[i],
          onTap: () => _openDetail(_items[i]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// List-mode tile
// ---------------------------------------------------------------------------

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
                  errorBuilder: (ctx, e, s) =>
                      _PosterPlaceholder(mediaType: result.mediaType),
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
