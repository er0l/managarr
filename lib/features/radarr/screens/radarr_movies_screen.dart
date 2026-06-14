import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/byte_formatter.dart';
import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
import '../models/radarr_options.dart';
import '../providers/radarr_providers.dart';
import '../widgets/movie_card.dart';
import 'radarr_movie_detail_screen.dart';

class RadarrMoviesScreen extends ConsumerStatefulWidget {
  const RadarrMoviesScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<RadarrMoviesScreen> createState() => _RadarrMoviesScreenState();
}

class _RadarrMoviesScreenState extends ConsumerState<RadarrMoviesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controller with current provider value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(radarrSearchQueryProvider(widget.instance.id));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortBottomSheet() {
    final currentSort = ref.read(radarrSortOptionProvider(widget.instance.id));
    final ascending = ref.read(radarrSortAscendingProvider(widget.instance.id));

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Row(
                children: [
                  Text('Sort by', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: () {
                      ref.read(radarrSortAscendingProvider(widget.instance.id).notifier).state = !ascending;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RadioGroup<RadarrSortOption>(
                groupValue: currentSort,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(radarrSortOptionProvider(widget.instance.id).notifier).state = val;
                    Navigator.pop(context);
                  }
                },
                child: ListView(
                  children: RadarrSortOption.values
                      .map((option) => RadioListTile<RadarrSortOption>(
                            title: Text(option.label),
                            value: option,
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

  void _showFilterBottomSheet() {
    final currentFilter = ref.read(radarrFilterOptionProvider(widget.instance.id));

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Text('Filter by', style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: RadioGroup<RadarrFilterOption>(
                groupValue: currentFilter,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(radarrFilterOptionProvider(widget.instance.id).notifier).state = val;
                    Navigator.pop(context);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: RadarrFilterOption.values
                      .map((option) => RadioListTile<RadarrFilterOption>(
                            title: Text(option.label),
                            value: option,
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
    final moviesAsync = ref.watch(radarrMoviesProvider(widget.instance));
    final filteredMovies = ref.watch(radarrFilteredMoviesProvider(widget.instance));
    final displayMode = ref.watch(radarrDisplayModeProvider(widget.instance.id));
    final query = ref.watch(radarrSearchQueryProvider(widget.instance.id));
    final currentSort = ref.watch(radarrSortOptionProvider(widget.instance.id));
    final currentFilter = ref.watch(radarrFilterOptionProvider(widget.instance.id));

    return Column(
      children: [
        // Search & Controls bar
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.pageHorizontal,
            Spacing.s12,
            Spacing.pageHorizontal,
            Spacing.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: moviesAsync.value?.length != null
                        ? 'Search ${moviesAsync.value!.length} movies…'
                        : 'Search movies…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(radarrSearchQueryProvider(widget.instance.id).notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => ref.read(radarrSearchQueryProvider(widget.instance.id).notifier).state = v,
                ),
              ),
              const SizedBox(width: Spacing.s8),
              _ControlButton(
                icon: Icons.filter_list,
                isActive: currentFilter != RadarrFilterOption.all,
                onTap: _showFilterBottomSheet,
              ),
              const SizedBox(width: Spacing.s4),
              _ControlButton(
                icon: Icons.sort,
                isActive: currentSort != RadarrSortOption.alphabetical,
                onTap: _showSortBottomSheet,
              ),
            ],
          ),
        ),
        // Movie list/grid
        Expanded(
          child: moviesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(radarrMoviesProvider(widget.instance)),
            ),
            data: (_) {
              if (filteredMovies.isEmpty) {
                return Center(
                  child: Text(
                    query.isNotEmpty ? 'No results for "$query"' : 'No movies found',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.tealPrimary,
                onRefresh: () async =>
                    ref.invalidate(radarrMoviesProvider(widget.instance)),
                child: displayMode == DisplayMode.grid
                    ? _MovieGrid(movies: filteredMovies, instance: widget.instance)
                    : _MovieList(movies: filteredMovies, instance: widget.instance),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      onPressed: onTap,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: isActive ? colorScheme.primaryContainer : null,
        foregroundColor: isActive ? colorScheme.onPrimaryContainer : null,
      ),
      icon: Icon(icon),
    );
  }
}

class _MovieGrid extends StatelessWidget {
  const _MovieGrid({required this.movies, required this.instance});
  final List<RadarrMovie> movies;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        Spacing.pageHorizontal, 0,
        Spacing.pageHorizontal, Spacing.s24,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
        crossAxisSpacing: Spacing.cardGap,
        mainAxisSpacing: Spacing.cardGap,
        childAspectRatio: 0.62,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return MovieCard(
          movie: movie,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RadarrMovieDetailScreen(
                movie: movie,
                instance: instance,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MovieList extends StatelessWidget {
  const _MovieList({required this.movies, required this.instance});
  final List<RadarrMovie> movies;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        final movie = movies[index];
        return _MovieTile(
          movie: movie,
          instance: instance,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RadarrMovieDetailScreen(
                movie: movie,
                instance: instance,
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatRuntime(int minutes) {
  if (minutes <= 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

class _MovieTile extends ConsumerWidget {
  const _MovieTile({required this.movie, required this.instance, required this.onTap});
  final RadarrMovie movie;
  final Instance instance;
  final VoidCallback onTap;

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final api = ref.read(radarrApiProvider(instance));
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (action) {
        case 'monitor':
          await api.toggleMonitorMovie(movie.id, !movie.monitored);
          ref.invalidate(radarrMoviesProvider(instance));
        case 'search':
          await api.searchMovie(movie.id);
          messenger.showSnackBar(const SnackBar(
            content: Text('Search started'),
            behavior: SnackBarBehavior.floating,
          ));
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Remove Movie'),
              content: Text('Remove "${movie.title}" from Radarr?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.statusOffline),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await api.deleteMovie(movie.id);
            ref.invalidate(radarrMoviesProvider(instance));
          }
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posterUrl = movie.posterUrl;
    final fanartUrl = movie.fanartUrl;
    final accentColor = ServiceType.radarr.brandColor;

    final statusColor = movie.hasFile
        ? AppColors.statusOnline
        : movie.monitored
            ? AppColors.statusWarning
            : AppColors.statusUnknown;

    final cardBg = isDark ? const Color(0xFF141E2E) : const Color(0xFFF2F4F7);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.pageHorizontal,
        vertical: 4,
      ),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: SizedBox(
            height: 112,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fanart backdrop bleed at low opacity
                if (fanartUrl != null)
                  Positioned.fill(
                    child: Image.network(
                      fanartUrl,
                      fit: BoxFit.cover,
                      color: Colors.black.withAlpha(isDark ? 184 : 210),
                      colorBlendMode: BlendMode.darken,
                      errorBuilder: (context, e, st) => const SizedBox.shrink(),
                    ),
                  ),
                // Gradient overlay so text is readable regardless of fanart
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          cardBg,
                          cardBg.withAlpha(isDark ? 200 : 230),
                          cardBg.withAlpha(isDark ? 120 : 160),
                        ],
                        stops: const [0, 0.55, 1],
                      ),
                    ),
                  ),
                ),
                // 3-dot context menu — top-right corner
                Positioned(
                  top: 0,
                  right: 0,
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert,
                      size: 18,
                      color: Colors.white60,
                    ),
                    onSelected: (action) => _handleAction(context, ref, action),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'monitor',
                        child: ListTile(
                          leading: Icon(
                            movie.monitored ? Icons.bookmark_remove_outlined : Icons.bookmark_add_outlined,
                          ),
                          title: Text(movie.monitored ? 'Unmonitor' : 'Monitor'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'search',
                        child: ListTile(
                          leading: Icon(Icons.search),
                          title: Text('Search'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, color: AppColors.statusOffline),
                          title: Text('Remove', style: TextStyle(color: AppColors.statusOffline)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                // Foreground content
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      // Poster
                      Hero(
                        tag: 'radarr-poster-${movie.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 62,
                            height: 92,
                            child: posterUrl != null
                                ? Image.network(posterUrl, fit: BoxFit.cover)
                                : Container(
                                    color: AppColors.tealDark,
                                    alignment: Alignment.center,
                                    child: Text(
                                      movie.title.isNotEmpty ? movie.title[0] : 'M',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Title + status dot
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  margin: const EdgeInsets.only(right: 6, top: 1),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: statusColor.withAlpha(100),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    movie.title,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            // Year · Runtime · Cert · Rating  [▶] [✓]
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    [
                                      '${movie.year}',
                                      if (movie.runtime != null && movie.runtime! > 0)
                                        _formatRuntime(movie.runtime!),
                                      if (movie.certification != null &&
                                          movie.certification!.isNotEmpty)
                                        movie.certification!,
                                      if (movie.tmdbRating != null)
                                        '★ ${movie.tmdbRating!.toStringAsFixed(1)}',
                                    ].join(' · '),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                // Status icon indicators
                                if (movie.youtubeTrailerId != null &&
                                    movie.youtubeTrailerId!.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.smart_display_outlined,
                                    size: 13,
                                    color: AppColors.textSecondary.withAlpha(180),
                                  ),
                                ],
                                if (movie.hasFile) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.check_circle_outline,
                                    size: 13,
                                    color: AppColors.statusOnline,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Bottom chips row
                            Row(
                              children: [
                                // File size chip
                                if (movie.hasFile &&
                                    movie.sizeOnDisk != null &&
                                    movie.sizeOnDisk! > 0) ...[
                                  _Chip(
                                    label: ByteFormatter.format(movie.sizeOnDisk!),
                                    color: AppColors.statusOnline,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                // Quality badge
                                if (movie.qualityName != null &&
                                    movie.qualityName!.isNotEmpty)
                                  _Chip(
                                    label: movie.qualityName!,
                                    color: accentColor,
                                  ),
                                // Monitor icon (right-aligned)
                                const Spacer(),
                                Icon(
                                  movie.monitored
                                      ? Icons.bookmark
                                      : Icons.bookmark_border,
                                  size: 16,
                                  color: movie.monitored
                                      ? accentColor
                                      : AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: AppColors.statusOffline),
            const SizedBox(height: Spacing.s16),
            Text(
              'Could not connect',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: Spacing.s8),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            const SizedBox(height: Spacing.s24),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.tealPrimary,
                foregroundColor: AppColors.textOnPrimary,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
