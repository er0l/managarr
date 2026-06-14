import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/byte_formatter.dart';
import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text =
          ref.read(radarrSearchQueryProvider(widget.instance.id));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(radarrMoviesProvider(widget.instance));
    final filteredMovies =
        ref.watch(radarrFilteredMoviesProvider(widget.instance));
    final displayMode =
        ref.watch(radarrDisplayModeProvider(widget.instance.id));
    final query = ref.watch(radarrSearchQueryProvider(widget.instance.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.pageHorizontal,
            Spacing.s12,
            Spacing.pageHorizontal,
            Spacing.s8,
          ),
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
                        ref
                            .read(radarrSearchQueryProvider(widget.instance.id)
                                .notifier)
                            .state = '';
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: AppColors.tealPrimary.withAlpha(180),
                  width: 1.5,
                ),
              ),
              filled: true,
            ),
            onChanged: (v) => ref
                .read(
                    radarrSearchQueryProvider(widget.instance.id).notifier)
                .state = v,
          ),
        ),
        Expanded(
          child: moviesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => _ErrorView(
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(radarrMoviesProvider(widget.instance)),
            ),
            data: (_) {
              if (filteredMovies.isEmpty) {
                return Center(
                  child: Text(
                    query.isNotEmpty
                        ? 'No results for "$query"'
                        : 'No movies found',
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
                    ? _MovieGrid(
                        movies: filteredMovies, instance: widget.instance)
                    : _MovieList(
                        movies: filteredMovies, instance: widget.instance),
              );
            },
          ),
        ),
      ],
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
        Spacing.pageHorizontal,
        0,
        Spacing.pageHorizontal,
        Spacing.s24,
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

String _formatStatus(String? status) {
  if (status == null || status.isEmpty) return '';
  switch (status.toLowerCase()) {
    case 'released':
      return 'Released';
    case 'incinemas':
      return 'In Cinemas';
    case 'announced':
      return 'Announced';
    case 'tba':
      return 'TBA';
    default:
      return status[0].toUpperCase() + status.substring(1);
  }
}

class _MovieTile extends ConsumerWidget {
  const _MovieTile(
      {required this.movie, required this.instance, required this.onTap});
  final RadarrMovie movie;
  final Instance instance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posterUrl = movie.posterUrl;
    final fanartUrl = movie.fanartUrl;
    final accentColor = ServiceType.radarr.brandColor;

    final profilesAsync = ref.watch(radarrQualityProfilesProvider(instance));
    final profileName = profilesAsync.valueOrNull
        ?.where((p) => p.id == movie.qualityProfileId)
        .map((p) => p.name)
        .firstOrNull;

    final cardBg = isDark ? const Color(0xFF141E2E) : const Color(0xFFF2F4F7);

    final line2Parts = [
      '${movie.year}',
      if (movie.runtime != null && movie.runtime! > 0)
        _formatRuntime(movie.runtime!),
      if (movie.studio != null && movie.studio!.isNotEmpty) movie.studio!,
    ];

    final line3Parts = [
      if (profileName != null && profileName.isNotEmpty) profileName,
      if (movie.status != null) _formatStatus(movie.status),
      if (movie.added != null)
        'Added ${DateFormat('MMM d, y').format(movie.added!)}',
    ];

    return Opacity(
      opacity: (!movie.monitored && !movie.hasFile) ? 0.55 : 1.0,
      child: Padding(
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
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (fanartUrl != null)
                    Positioned.fill(
                      child: Image.network(
                        fanartUrl,
                        fit: BoxFit.cover,
                        color:
                            Colors.black.withAlpha(isDark ? 184 : 210),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, e, st) =>
                            const SizedBox.shrink(),
                      ),
                    ),
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
                              width: 60,
                              height: 88,
                              child: posterUrl != null
                                  ? Image.network(posterUrl,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.tealDark,
                                      alignment: Alignment.center,
                                      child: Text(
                                        movie.title.isNotEmpty
                                            ? movie.title[0]
                                            : 'M',
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
                              // Line 1: Title
                              Text(
                                movie.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              // Line 2: Year · Runtime · Studio
                              Text(
                                line2Parts.join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              // Line 3: Profile · Status · DateAdded
                              Text(
                                line3Parts.join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary
                                      .withAlpha(200),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Line 4: icons + filesize
                              Row(
                                children: [
                                  if (movie.youtubeTrailerId != null &&
                                      movie.youtubeTrailerId!.isNotEmpty) ...[
                                    Icon(
                                      Icons.smart_display_outlined,
                                      size: 14,
                                      color: AppColors.textSecondary
                                          .withAlpha(180),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  Icon(
                                    movie.monitored
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    size: 14,
                                    color: movie.monitored
                                        ? accentColor
                                        : AppColors.textSecondary,
                                  ),
                                  if (movie.hasFile) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: AppColors.statusOnline,
                                    ),
                                  ],
                                  const Spacer(),
                                  if (movie.hasFile &&
                                      movie.sizeOnDisk != null &&
                                      movie.sizeOnDisk! > 0)
                                    _Chip(
                                      label: ByteFormatter.format(
                                          movie.sizeOnDisk!),
                                      color: AppColors.statusOnline,
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
            const Icon(Icons.cloud_off,
                size: 48, color: AppColors.statusOffline),
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
