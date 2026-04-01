import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/movie.dart';
import '../providers/radarr_providers.dart';
import '../widgets/movie_card.dart';
import 'radarr_movie_detail_screen.dart';

class RadarrCalendarScreen extends ConsumerWidget {
  const RadarrCalendarScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(radarrCalendarProvider(instance));
    final displayMode = ref.watch(radarrDisplayModeProvider(instance.id));

    return calendarAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (movies) {
        if (movies.isEmpty) {
          return const Center(child: Text('No upcoming releases found'));
        }

        // Group by date — only include entries from today onwards
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final grouped = <DateTime, List<RadarrMovie>>{};
        for (final m in movies) {
          final date = m.digitalRelease ?? m.physicalRelease ?? m.inCinemas;
          if (date != null) {
            final day = DateTime(date.year, date.month, date.day);
            if (!day.isBefore(today)) {
              grouped.putIfAbsent(day, () => []).add(m);
            }
          }
        }

        final sortedDates = grouped.keys.toList()..sort();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(radarrCalendarProvider(instance)),
          child: CustomScrollView(
            slivers: [
              for (final date in sortedDates) ...[
                SliverToBoxAdapter(
                  child: _DateHeader(date: date),
                ),
                if (displayMode == DisplayMode.grid)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                        crossAxisSpacing: Spacing.cardGap,
                        mainAxisSpacing: Spacing.cardGap,
                        childAspectRatio: 0.62,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final movie = grouped[date]![index];
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
                        childCount: grouped[date]!.length,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final movie = grouped[date]![index];
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
                      childCount: grouped[date]!.length,
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: Spacing.s24)),
            ],
          ),
        );
      },
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;
    final isTomorrow = date == today.add(const Duration(days: 1));

    String text;
    if (isToday) {
      text = 'Today';
    } else if (isTomorrow) {
      text = 'Tomorrow';
    } else {
      text = DateFormat('EEEE, MMMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.pageHorizontal,
        Spacing.s16,
        Spacing.pageHorizontal,
        Spacing.s8,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.tealDark,
              fontWeight: FontWeight.bold,
            ),
      ),
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
                  child: const Text(
                    '?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
        ),
      ),
      title: Text(
        movie.title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        movie.status ?? 'Unknown',
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
      onTap: onTap,
    );
  }
}
