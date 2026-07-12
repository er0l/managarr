import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/spacing.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../calendar/providers/calendar_providers.dart';

/// How far ahead the dashboard looks for upcoming releases.
const _lookaheadDays = 14;
const _maxEntries = 20;

/// "Upcoming" — next two weeks of releases from the unified calendar,
/// as a horizontal poster rail. Tapping goes to the Calendar tab.
class UpcomingSection extends ConsumerWidget {
  const UpcomingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarAsync = ref.watch(unifiedCalendarProvider);

    return calendarAsync.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Upcoming'),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal),
            child: Row(
              children: [
                ShimmerBox(width: 100, height: 150, borderRadius: 12),
                SizedBox(width: Spacing.s12),
                ShimmerBox(width: 100, height: 150, borderRadius: 12),
                SizedBox(width: Spacing.s12),
                ShimmerBox(width: 100, height: 150, borderRadius: 12),
              ],
            ),
          ),
        ],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final horizon = today.add(const Duration(days: _lookaheadDays));
        final upcoming = entries
            .where((e) => !e.date.isBefore(today) && !e.date.isAfter(horizon))
            .take(_maxEntries)
            .toList();

        if (upcoming.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Upcoming',
              trailing: TextButton(
                onPressed: () => context.go('/calendar'),
                child: const Text('See all'),
              ),
            ),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.pageHorizontal,
                ),
                itemCount: upcoming.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: Spacing.s12),
                itemBuilder: (context, index) =>
                    _UpcomingCard(entry: upcoming[index]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.entry});

  final CalendarEntry entry;

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return DateFormat('E d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 100,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/calendar'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 100,
                    height: 150,
                    child: entry.posterUrl != null
                        ? Image.network(
                            entry.posterUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                const _PosterFallback(),
                          )
                        : const _PosterFallback(),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.typeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              entry.title,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _dayLabel(entry.date),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.movie_outlined,
        color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
      ),
    );
  }
}
