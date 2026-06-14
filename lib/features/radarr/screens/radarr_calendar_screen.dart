import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
import '../providers/radarr_providers.dart';
import 'radarr_movie_detail_screen.dart';

// Returns the nearest future release date from the available dates on a movie.
DateTime? _nearestFutureRelease(RadarrMovie movie) {
  final now = DateTime.now();
  final candidates = [
    movie.digitalRelease,
    movie.physicalRelease,
    movie.inCinemas,
  ].whereType<DateTime>().where((d) => d.isAfter(now)).toList();
  if (candidates.isEmpty) return null;
  candidates.sort();
  return candidates.first;
}

String _availabilityText(DateTime? releaseDate) {
  if (releaseDate == null) return 'Availability Unknown';
  final days = releaseDate.difference(DateTime.now()).inDays;
  if (days == 0) return 'Available Today';
  if (days == 1) return 'Available Tomorrow';
  return 'Available in $days Days';
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

class RadarrCalendarScreen extends ConsumerWidget {
  const RadarrCalendarScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moviesAsync = ref.watch(radarrMoviesProvider(instance));
    final profilesAsync = ref.watch(radarrQualityProfilesProvider(instance));

    return moviesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allMovies) {
        // Upcoming: monitored movies without a file, not yet released
        final upcoming = allMovies
            .where((m) => m.monitored && !m.hasFile)
            .toList();

        if (upcoming.isEmpty) {
          return const Center(child: Text('No upcoming movies'));
        }

        // Sort: movies with a future date first (ascending), unknowns last
        upcoming.sort((a, b) {
          final da = _nearestFutureRelease(a);
          final db = _nearestFutureRelease(b);
          if (da == null && db == null) return a.title.compareTo(b.title);
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

        final profiles = profilesAsync.valueOrNull ?? [];

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(radarrMoviesProvider(instance)),
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: Spacing.s24),
            itemCount: upcoming.length,
            itemBuilder: (context, index) {
              final movie = upcoming[index];
              final releaseDate = _nearestFutureRelease(movie);
              final profileName = profiles
                  .where((p) => p.id == movie.qualityProfileId)
                  .map((p) => p.name)
                  .firstOrNull;
              return _UpcomingTile(
                movie: movie,
                releaseDate: releaseDate,
                profileName: profileName,
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
                onSearch: () async {
                  final api = ref.read(radarrApiProvider(instance));
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
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({
    required this.movie,
    required this.releaseDate,
    required this.profileName,
    required this.instance,
    required this.onTap,
    required this.onSearch,
  });

  final RadarrMovie movie;
  final DateTime? releaseDate;
  final String? profileName;
  final Instance instance;
  final VoidCallback onTap;
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
      if (movie.inCinemas != null)
        DateFormat('MMM y').format(movie.inCinemas!),
    ].where((s) => s.isNotEmpty).toList();

    final availText = _availabilityText(releaseDate);
    final isUnknown = releaseDate == null;

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
          onTap: onTap,
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
                      // Line 4: Availability in teal or muted
                      Text(
                        availText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isUnknown
                              ? AppColors.textSecondary
                              : AppColors.tealPrimary,
                          fontWeight: isUnknown
                              ? FontWeight.normal
                              : FontWeight.w600,
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
