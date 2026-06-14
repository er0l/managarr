import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
import '../providers/radarr_providers.dart';
import 'radarr_movie_detail_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<DateTime> _allReleaseDates(RadarrMovie movie) {
  return [
    movie.digitalRelease,
    movie.physicalRelease,
    movie.inCinemas,
  ].whereType<DateTime>().toList();
}

DateTime? _nearestFutureRelease(RadarrMovie movie) {
  final now = DateTime.now();
  final candidates =
      _allReleaseDates(movie).where((d) => d.isAfter(now)).toList();
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

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class RadarrCalendarScreen extends ConsumerStatefulWidget {
  const RadarrCalendarScreen({super.key, required this.instance});
  final Instance instance;

  @override
  ConsumerState<RadarrCalendarScreen> createState() =>
      _RadarrCalendarScreenState();
}

class _RadarrCalendarScreenState extends ConsumerState<RadarrCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final moviesAsync = ref.watch(radarrMoviesProvider(widget.instance));
    final profilesAsync =
        ref.watch(radarrQualityProfilesProvider(widget.instance));
    final theme = Theme.of(context);

    return moviesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allMovies) {
        final upcoming = allMovies
            .where((m) => m.monitored && !m.hasFile)
            .toList();

        // Build day → movies map (using all release dates)
        final byDay = <DateTime, List<RadarrMovie>>{};
        for (final movie in upcoming) {
          for (final date in _allReleaseDates(movie)) {
            final key = DateTime(date.year, date.month, date.day);
            byDay.putIfAbsent(key, () => []).add(movie);
          }
        }

        // Movies for selected day
        final selKey = DateTime(
            _selectedDay.year, _selectedDay.month, _selectedDay.day);
        final dayMovies = (byDay[selKey] ?? upcoming)
            .where((m) =>
                _searchTerm.isEmpty ||
                m.title
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()))
            .toList();

        // Sort by nearest release date
        dayMovies.sort((a, b) {
          final da = _nearestFutureRelease(a);
          final db = _nearestFutureRelease(b);
          if (da == null && db == null) return a.title.compareTo(b.title);
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

        final profiles = profilesAsync.valueOrNull ?? [];

        // Show all upcoming if nothing for selected day (fallback)
        final isFiltered = byDay[selKey] != null;

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(radarrMoviesProvider(widget.instance)),
          color: AppColors.tealPrimary,
          child: CustomScrollView(
            slivers: [
              // Month calendar
              SliverToBoxAdapter(
                child: TableCalendar<RadarrMovie>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  calendarFormat: CalendarFormat.month,
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Month',
                  },
                  eventLoader: (day) {
                    final key = DateTime(day.year, day.month, day.day);
                    return byDay[key] ?? [];
                  },
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _selectedDay = selected;
                      _focusedDay = focused;
                    });
                  },
                  onPageChanged: (focused) {
                    setState(() => _focusedDay = focused);
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.tealPrimary.withAlpha(60),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.tealPrimary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle:
                        const TextStyle(color: Colors.white),
                    markerDecoration: const BoxDecoration(
                      color: AppColors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: theme.textTheme.titleMedium!
                        .copyWith(fontWeight: FontWeight.w700),
                    leftChevronIcon: const Icon(Icons.chevron_left,
                        color: AppColors.tealPrimary),
                    rightChevronIcon: const Icon(Icons.chevron_right,
                        color: AppColors.tealPrimary),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: theme.textTheme.bodySmall!
                        .copyWith(color: AppColors.textSecondary),
                    weekendStyle: theme.textTheme.bodySmall!
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: Divider(height: 1)),
              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.pageHorizontal,
                    Spacing.s12,
                    Spacing.pageHorizontal,
                    Spacing.s8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search upcoming movies…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchTerm.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchTerm = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
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
                    onChanged: (v) => setState(() => _searchTerm = v.trim()),
                  ),
                ),
              ),
              // Day label
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.pageHorizontal, 4, Spacing.pageHorizontal, 8),
                  child: Text(
                    isFiltered
                        ? _selectedDayLabel(_selectedDay)
                        : 'All Upcoming',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.tealDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Movie list
              if (dayMovies.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        isFiltered
                            ? 'No upcoming movies on this date'
                            : 'No upcoming movies',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final movie = dayMovies[i];
                      final releaseDate = _nearestFutureRelease(movie);
                      final profileName = profiles
                          .where((p) => p.id == movie.qualityProfileId)
                          .map((p) => p.name)
                          .firstOrNull;
                      return _UpcomingTile(
                        movie: movie,
                        releaseDate: releaseDate,
                        profileName: profileName,
                        instance: widget.instance,
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => RadarrMovieDetailScreen(
                              movie: movie,
                              instance: widget.instance,
                            ),
                          ),
                        ),
                        onSearch: () async {
                          final api = ref.read(
                              radarrApiProvider(widget.instance));
                          try {
                            await api.searchMovie(movie.id);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Search started'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
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
                    childCount: dayMovies.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: Spacing.s24)),
            ],
          ),
        );
      },
    );
  }

  String _selectedDayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (isSameDay(day, today)) return 'Today';
    if (isSameDay(day, tomorrow)) return 'Tomorrow';
    return DateFormat('EEEE, MMMM d').format(day);
  }
}

// ---------------------------------------------------------------------------
// Tile (unchanged from previous version)
// ---------------------------------------------------------------------------

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
    final cardBg =
        isDark ? const Color(0xFF141E2E) : const Color(0xFFF2F4F7);

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
        DateFormat('MMM d, y').format(movie.inCinemas!),
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      Text(
                        line2Parts.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
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
