import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/calendar.dart';
import '../providers/sonarr_providers.dart';

class SonarrCalendarScreen extends ConsumerWidget {
  const SonarrCalendarScreen({super.key, required this.instance});

  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(sonarrCalendarProvider(instance));
    final displayMode = ref.watch(sonarrDisplayModeProvider(instance.id));

    return calendarAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (episodes) {
        if (episodes.isEmpty) {
          return const Center(child: Text('No upcoming episodes found'));
        }

        // Group by date
        final grouped = <DateTime, List<SonarrCalendar>>{};
        for (final e in episodes) {
          if (e.airDateUtc != null) {
            final date = e.airDateUtc!.toLocal();
            final day = DateTime(date.year, date.month, date.day);
            grouped.putIfAbsent(day, () => []).add(e);
          }
        }

        final sortedDates = grouped.keys.toList()..sort();

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(sonarrCalendarProvider(instance)),
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
                          final episode = grouped[date]![index];
                          return _EpisodeGridCard(episode: episode);
                        },
                        childCount: grouped[date]!.length,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final episode = grouped[date]![index];
                        return _EpisodeTile(episode: episode);
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

class _EpisodeGridCard extends StatelessWidget {
  const _EpisodeGridCard({required this.episode});
  final SonarrCalendar episode;

  @override
  Widget build(BuildContext context) {
    final posterUrl = episode.series?.posterUrl;
    final title = episode.series?.title ?? 'Unknown Series';
    final epTitle = episode.title ?? 'Unknown Episode';
    final epNum = 'S${episode.seasonNumber?.toString().padLeft(2, '0')}E${episode.episodeNumber?.toString().padLeft(2, '0')}';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (posterUrl != null)
            Image.network(posterUrl, fit: BoxFit.cover)
          else
            Container(color: AppColors.tealDark),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(200)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$epNum: $epTitle',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode});
  final SonarrCalendar episode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = episode.series?.posterUrl;
    final title = episode.series?.title ?? 'Unknown Series';
    final epTitle = episode.title ?? 'Unknown Episode';
    final epNum = 'S${episode.seasonNumber?.toString().padLeft(2, '0')}E${episode.episodeNumber?.toString().padLeft(2, '0')}';

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
              : Container(color: AppColors.tealDark),
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '$epNum: $epTitle',
        style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}
