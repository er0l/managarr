import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/models/service_type.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/radarr/providers/radarr_providers.dart';
import '../../../features/radarr/screens/radarr_movie_detail_screen.dart';
import '../../../features/settings/providers/instances_provider.dart';
import '../../../features/sonarr/providers/sonarr_providers.dart';
import '../../../features/sonarr/screens/sonarr_series_detail_screen.dart';
import '../providers/calendar_providers.dart';

class UnifiedCalendarScreen extends ConsumerStatefulWidget {
  const UnifiedCalendarScreen({super.key});

  @override
  ConsumerState<UnifiedCalendarScreen> createState() =>
      _UnifiedCalendarScreenState();
}

class _UnifiedCalendarScreenState
    extends ConsumerState<UnifiedCalendarScreen> {
  int _monthOffset = 0;
  DateTime? _selectedDate;

  DateTime get _monthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month + _monthOffset, 1);
  }

  Future<void> _refresh() async {
    final grouped = ref.read(instancesByServiceProvider);
    for (final inst in grouped[ServiceType.radarr] ?? []) {
      ref.invalidate(radarrCalendarProvider(inst));
    }
    for (final inst in grouped[ServiceType.sonarr] ?? []) {
      ref.invalidate(sonarrCalendarProvider(inst));
    }
    ref.invalidate(unifiedCalendarProvider);
    await ref
        .read(unifiedCalendarProvider.future)
        .catchError((_) => <CalendarEntry>[]);
  }

  void _onDayTap(DateTime day, List<CalendarEntry> entries) {
    if (entries.isEmpty) return;
    setState(() {
      _selectedDate = _selectedDate == day ? null : day;
    });
  }

  void _onMonthChange(int delta) {
    setState(() {
      _monthOffset += delta;
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(unifiedCalendarProvider);
    final isTable = ref.watch(calendarViewModeProvider);

    return calAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppColors.statusOffline),
            const SizedBox(height: 12),
            Text('$e'),
            const SizedBox(height: 8),
            TextButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      ),
      data: (entries) => RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.tealPrimary,
        child: isTable
            ? _MonthBody(
                entries: entries,
                monthStart: _monthStart,
                selectedDate: _selectedDate,
                onMonthChange: _onMonthChange,
                onDayTap: _onDayTap,
              )
            : _ListBody(entries: entries),
      ),
    );
  }
}

// ─── Navigation helper ────────────────────────────────────────────────────────

void _openEntry(BuildContext context, CalendarEntry entry) {
  if (entry.movie != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RadarrMovieDetailScreen(
          movie: entry.movie!,
          instance: entry.instance,
        ),
      ),
    );
  } else if (entry.series != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SonarrSeriesDetailScreen(
          series: entry.series!,
          instance: entry.instance,
        ),
      ),
    );
  }
}

// ─── List body ────────────────────────────────────────────────────────────────

class _ListBody extends StatelessWidget {
  const _ListBody({required this.entries});

  final List<CalendarEntry> entries;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcoming = entries.where((e) => !e.date.isBefore(today)).toList();

    if (upcoming.isEmpty) {
      return ListView(children: const [
        SizedBox(height: 120),
        Center(child: Text('No upcoming releases')),
      ]);
    }

    final grouped = <DateTime, List<CalendarEntry>>{};
    for (final e in upcoming) {
      grouped.putIfAbsent(e.date, () => []).add(e);
    }
    final dates = grouped.keys.toList()..sort();

    return CustomScrollView(
      slivers: [
        for (final date in dates) ...[
          SliverToBoxAdapter(child: _DateHeader(date: date)),
          SliverList.separated(
            itemCount: grouped[date]!.length,
            separatorBuilder: (_, i) => const Divider(height: 1),
            itemBuilder: (ctx, i) => _EntryTile(entry: grouped[date]![i]),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
    final String label;
    if (date == today) {
      label = 'Today';
    } else if (date == today.add(const Duration(days: 1))) {
      label = 'Tomorrow';
    } else {
      label = DateFormat('EEEE, MMMM d').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.tealDark,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canNavigate = entry.movie != null || entry.series != null;

    return ListTile(
      onTap: canNavigate ? () => _openEntry(context, entry) : null,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 40,
          height: 58,
          child: entry.posterUrl != null
              ? Image.network(
                  entry.posterUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => _Placeholder(entry: entry),
                )
              : _Placeholder(entry: entry),
        ),
      ),
      title: Text(
        entry.title,
        style:
            theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.subtitle != null && entry.subtitle!.isNotEmpty)
            Text(
              entry.subtitle!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 3),
          Row(
            children: [
              _TypeBadge(entry: entry),
              const SizedBox(width: 6),
              _StatusBadge(entry: entry),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  entry.instanceName,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: canNavigate
          ? const Icon(Icons.chevron_right,
              size: 20, color: AppColors.textSecondary)
          : null,
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.entry});
  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: entry.typeColor.withAlpha(40),
      alignment: Alignment.center,
      child: Icon(
        entry.type == CalendarEntryType.movie
            ? Icons.movie_outlined
            : Icons.tv_outlined,
        color: entry.typeColor,
        size: 20,
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.entry});
  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: entry.typeColor.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: entry.typeColor.withAlpha(100)),
      ),
      child: Text(
        entry.type == CalendarEntryType.movie ? 'Movie' : 'Episode',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: entry.typeColor),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.entry});
  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.hasFile) {
      final label = entry.qualityName != null
          ? 'Downloaded · ${entry.qualityName}'
          : 'Downloaded';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.green.withAlpha(120)),
        ),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: Colors.green),
        ),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (!entry.date.isBefore(today)) {
      // Today or future = unaired
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(30),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.withAlpha(100)),
        ),
        child: Text(
          'Unaired',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// ─── Month table body ─────────────────────────────────────────────────────────

class _MonthBody extends StatelessWidget {
  const _MonthBody({
    required this.entries,
    required this.monthStart,
    required this.selectedDate,
    required this.onMonthChange,
    required this.onDayTap,
  });

  final List<CalendarEntry> entries;
  final DateTime monthStart;
  final DateTime? selectedDate;
  final void Function(int) onMonthChange;
  final void Function(DateTime, List<CalendarEntry>) onDayTap;

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, List<CalendarEntry>>{};
    for (final e in entries) {
      byDay.putIfAbsent(e.date, () => []).add(e);
    }

    final firstWeekday = monthStart.weekday; // 1=Mon, 7=Sun
    final gridStart = monthStart.subtract(Duration(days: firstWeekday - 1));
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);

    final weeks = <List<DateTime>>[];
    for (int w = 0; w < 6; w++) {
      final weekStart = gridStart.add(Duration(days: w * 7));
      if (weekStart.isAfter(monthEnd)) break;
      weeks.add(List.generate(7, (d) => weekStart.add(Duration(days: d))));
    }

    final selectedEntries =
        selectedDate != null ? (byDay[selectedDate!] ?? []) : <CalendarEntry>[];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Month navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => onMonthChange(-1),
            ),
            Text(
              DateFormat('MMMM yyyy').format(monthStart),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => onMonthChange(1),
            ),
          ],
        ),
        // Day-name header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children:
                const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
          ),
        ),
        const SizedBox(height: 4),
        // Calendar grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Table(
            border: TableBorder.all(
              color: Colors.grey.withAlpha(40),
              width: 0.5,
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: weeks
                .map((week) => TableRow(
                      children: week
                          .map((day) => _DayCell(
                                day: day,
                                entries: byDay[day] ?? [],
                                isCurrentMonth:
                                    day.month == monthStart.month,
                                isSelected: day == selectedDate,
                                onTap: () =>
                                    onDayTap(day, byDay[day] ?? []),
                              ))
                          .toList(),
                    ))
                .toList(),
          ),
        ),
        // Selected day panel
        if (selectedDate != null && selectedEntries.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.tealPrimary.withAlpha(80)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Text(
                    DateFormat('EEEE, MMMM d').format(selectedDate!),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.tealPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const Divider(height: 1),
                for (int i = 0; i < selectedEntries.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _EntryTile(entry: selectedEntries[i]),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.entries,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.onTap,
  });

  final DateTime day;
  final List<CalendarEntry> entries;
  final bool isCurrentMonth;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = day == today;
    const maxVisible = 2;
    final overflow = (entries.length - maxVisible).clamp(0, 99);

    return InkWell(
      onTap: entries.isNotEmpty ? onTap : null,
      child: Container(
        color: isSelected
            ? AppColors.tealPrimary.withAlpha(15)
            : null,
        padding: const EdgeInsets.all(3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Day number
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: isToday
                  ? const BoxDecoration(
                      color: AppColors.tealPrimary,
                      shape: BoxShape.circle,
                    )
                  : null,
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isToday ? FontWeight.bold : FontWeight.normal,
                  color: isToday
                      ? Colors.white
                      : isCurrentMonth
                          ? null
                          : AppColors.textSecondary.withAlpha(80),
                ),
              ),
            ),
            // Entry chips (max 2)
            for (int i = 0; i < entries.length && i < maxVisible; i++)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 2, vertical: 1),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: entries[i].typeColor.withAlpha(200),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  entries[i].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (overflow > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+$overflow more',
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }
}
