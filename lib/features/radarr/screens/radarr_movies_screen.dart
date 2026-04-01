import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
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
                    hintText: 'Search movies…',
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

class _MovieTile extends StatelessWidget {
  const _MovieTile({required this.movie, required this.onTap});
  final RadarrMovie movie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = movie.posterUrl;

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
              ? Image.network(posterUrl, fit: BoxFit.cover)
              : Container(
                  color: AppColors.tealDark,
                  alignment: Alignment.center,
                  child: Text(
                    movie.title.isNotEmpty ? movie.title[0] : 'M',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ),
      title: Text(
        movie.title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          '${movie.year}',
          if (movie.runtime != null) '${movie.runtime} min',
          if (movie.certification != null) movie.certification,
        ].join(' · '),
        style:
            theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      onTap: onTap,
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
