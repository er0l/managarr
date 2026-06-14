import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/calendar.dart';
import '../providers/sonarr_providers.dart';

class SonarrCalendarScreen extends ConsumerStatefulWidget {
  const SonarrCalendarScreen({super.key, required this.instance});
  final Instance instance;

  @override
  ConsumerState<SonarrCalendarScreen> createState() =>
      _SonarrCalendarScreenState();
}

class _SonarrCalendarScreenState extends ConsumerState<SonarrCalendarScreen> {
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
    final calendarAsync = ref.watch(sonarrCalendarProvider(widget.instance));
    final theme = Theme.of(context);

    return calendarAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (episodes) {
        // Build day → episodes map
        final byDay = <DateTime, List<SonarrCalendar>>{};
        for (final ep in episodes) {
          if (ep.airDateUtc != null) {
            final d = ep.airDateUtc!.toLocal();
            final key = DateTime(d.year, d.month, d.day);
            byDay.putIfAbsent(key, () => []).add(ep);
          }
        }

        // Episodes for selected day, filtered by search
        final selKey = DateTime(
            _selectedDay.year, _selectedDay.month, _selectedDay.day);
        final dayEpisodes = (byDay[selKey] ?? [])
            .where((ep) =>
                _searchTerm.isEmpty ||
                (ep.series?.title ?? '')
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()) ||
                (ep.title ?? '')
                    .toLowerCase()
                    .contains(_searchTerm.toLowerCase()))
            .toList();

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(sonarrCalendarProvider(widget.instance)),
          color: AppColors.tealPrimary,
          child: CustomScrollView(
            slivers: [
              // Month calendar
              SliverToBoxAdapter(
                child: TableCalendar<SonarrCalendar>(
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
              // Divider
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
                      hintText: 'Search episodes…',
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
              // Date label for selected day
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.pageHorizontal, 4, Spacing.pageHorizontal, 8),
                  child: Text(
                    _selectedDayLabel(_selectedDay),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.tealDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Episodes for selected day
              if (dayEpisodes.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No episodes airing on this date',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _EpisodeTile(episode: dayEpisodes[i]),
                    childCount: dayEpisodes.length,
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

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode});
  final SonarrCalendar episode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = episode.series?.posterUrl;
    final title = episode.series?.title ?? 'Unknown Series';
    final epTitle = episode.title ?? 'Unknown Episode';
    final epNum =
        'S${episode.seasonNumber?.toString().padLeft(2, '0')}E${episode.episodeNumber?.toString().padLeft(2, '0')}';
    final airTime = episode.airDateUtc != null
        ? DateFormat('h:mm a').format(episode.airDateUtc!.toLocal())
        : '';

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
        style:
            theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$epNum: $epTitle',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          if (airTime.isNotEmpty)
            Text(
              airTime,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.tealPrimary),
            ),
        ],
      ),
    );
  }
}
