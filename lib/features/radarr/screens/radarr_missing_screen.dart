import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
import '../providers/radarr_providers.dart';
import 'radarr_movie_detail_screen.dart';

class RadarrMissingScreen extends ConsumerStatefulWidget {
  const RadarrMissingScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<RadarrMissingScreen> createState() =>
      _RadarrMissingScreenState();
}

class _RadarrMissingScreenState extends ConsumerState<RadarrMissingScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RadarrMovie> _filterMissing(List<RadarrMovie> movies) {
    final q = _query.toLowerCase();
    return movies
        .where((m) =>
            m.monitored &&
            !m.hasFile &&
            (q.isEmpty || m.title.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) =>
          (a.sortTitle ?? a.title).toLowerCase().compareTo(
                (b.sortTitle ?? b.title).toLowerCase(),
              ));
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(radarrMoviesProvider(widget.instance));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search missing…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        Expanded(
          child: moviesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: AppColors.statusOffline),
                  const SizedBox(height: 12),
                  Text('$e'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(radarrMoviesProvider(widget.instance)),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (movies) {
              final missing = _filterMissing(movies);
              if (missing.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 48, color: AppColors.statusOnline),
                      SizedBox(height: 12),
                      Text('No missing movies'),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(radarrMoviesProvider(widget.instance)),
                color: AppColors.tealPrimary,
                child: ListView.separated(
                  itemCount: missing.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) =>
                      _MissingMovieTile(
                        movie: missing[i],
                        instance: widget.instance,
                      ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MissingMovieTile extends StatelessWidget {
  const _MissingMovieTile({required this.movie, required this.instance});

  final RadarrMovie movie;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = movie.posterUrl;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              RadarrMovieDetailScreen(movie: movie, instance: instance),
        ),
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 58,
          child: posterUrl != null
              ? Image.network(posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _PosterFallback(movie: movie))
              : _PosterFallback(movie: movie),
        ),
      ),
      title: Text(
        movie.title,
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          if (movie.year > 0) ...[
            Text('${movie.year}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(width: 8),
          ],
          if (movie.studio != null && movie.studio!.isNotEmpty)
            Expanded(
              child: Text(
                movie.studio!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right,
          size: 20, color: AppColors.textSecondary),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.movie});
  final RadarrMovie movie;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tealDark,
      alignment: Alignment.center,
      child: Text(
        movie.title.isNotEmpty ? movie.title[0] : '?',
        style: const TextStyle(
            color: Colors.white54, fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}
