import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
import '../providers/radarr_providers.dart';
import 'radarr_movie_detail_screen.dart';

// Find the most recent past release date to calculate "Released X ago".
DateTime? _mostRecentPastRelease(RadarrMovie movie) {
  final now = DateTime.now();
  final candidates = [
    movie.digitalRelease,
    movie.physicalRelease,
    movie.inCinemas,
  ].whereType<DateTime>().where((d) => d.isBefore(now)).toList();
  if (candidates.isEmpty) return null;
  candidates.sort();
  return candidates.last;
}

String _releasedAgoText(DateTime? releaseDate) {
  if (releaseDate == null) return 'Release date unknown';
  final diff = DateTime.now().difference(releaseDate);
  final days = diff.inDays;
  if (days == 0) return 'Released today';
  if (days == 1) return 'Released yesterday';
  if (days < 30) return 'Released $days days ago';
  final months = (days / 30.4375).round();
  if (months < 12) {
    return months == 1 ? 'Released 1 month ago' : 'Released $months months ago';
  }
  final years = (days / 365.25).round();
  return years == 1 ? 'Released 1 year ago' : 'Released $years years ago';
}

String _formatRuntime(int? minutes) {
  if (minutes == null || minutes <= 0) return '';
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
            (m.status?.toLowerCase() == 'released') &&
            (q.isEmpty || m.title.toLowerCase().contains(q)))
        .toList()
      ..sort((a, b) {
        final da = _mostRecentPastRelease(a);
        final db = _mostRecentPastRelease(b);
        if (da == null && db == null) return a.title.compareTo(b.title);
        if (da == null) return 1;
        if (db == null) return -1;
        // Most recently released first
        return db.compareTo(da);
      });
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(radarrMoviesProvider(widget.instance));
    final profilesAsync =
        ref.watch(radarrQualityProfilesProvider(widget.instance));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.pageHorizontal,
            12,
            Spacing.pageHorizontal,
            8,
          ),
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
            onChanged: (v) => setState(() => _query = v.trim()),
          ),
        ),
        Expanded(
          child: moviesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
              final profiles = profilesAsync.valueOrNull ?? [];

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
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: Spacing.s24),
                  itemCount: missing.length,
                  itemBuilder: (ctx, i) {
                    final movie = missing[i];
                    final releaseDate = _mostRecentPastRelease(movie);
                    final profileName = profiles
                        .where((p) => p.id == movie.qualityProfileId)
                        .map((p) => p.name)
                        .firstOrNull;
                    return _MissingTile(
                      movie: movie,
                      releaseDate: releaseDate,
                      profileName: profileName,
                      instance: widget.instance,
                      onSearch: () async {
                        final api =
                            ref.read(radarrApiProvider(widget.instance));
                        try {
                          await api.searchMovie(movie.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Search started'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
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

class _MissingTile extends StatelessWidget {
  const _MissingTile({
    required this.movie,
    required this.releaseDate,
    required this.profileName,
    required this.instance,
    required this.onSearch,
  });

  final RadarrMovie movie;
  final DateTime? releaseDate;
  final String? profileName;
  final Instance instance;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = movie.posterUrl;
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF141E2E) : const Color(0xFFF2F4F7);

    final line2Parts = [
      '${movie.year}',
      if (movie.runtime != null && movie.runtime! > 0)
        _formatRuntime(movie.runtime),
      if (movie.studio != null && movie.studio!.isNotEmpty) movie.studio!,
    ];

    final line3Parts = [
      if (profileName != null && profileName!.isNotEmpty) profileName!,
      _formatStatus(movie.status),
      if (releaseDate != null)
        DateFormat('MMM y').format(releaseDate!),
    ].where((s) => s.isNotEmpty).toList();

    final agoText = _releasedAgoText(releaseDate);

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
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RadarrMovieDetailScreen(movie: movie, instance: instance),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Poster
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 60,
                    height: 88,
                    child: posterUrl != null
                        ? Image.network(posterUrl, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.tealDark,
                            alignment: Alignment.center,
                            child: Text(
                              movie.title.isNotEmpty ? movie.title[0] : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 22,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                      // Line 3: Profile · Status · Date
                      Text(
                        line3Parts.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary.withAlpha(200),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Line 4: Released X ago in red/orange
                      Text(
                        agoText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFE05252),
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Search icon
                IconButton(
                  icon: Icon(
                    Icons.search,
                    color: AppColors.textSecondary.withAlpha(180),
                    size: 20,
                  ),
                  onPressed: onSearch,
                  tooltip: 'Search now',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
