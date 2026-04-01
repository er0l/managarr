import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../api/models/tautulli_graph_data.dart';
import '../providers/tautulli_providers.dart';

class TautulliGraphsScreen extends ConsumerStatefulWidget {
  const TautulliGraphsScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<TautulliGraphsScreen> createState() =>
      _TautulliGraphsScreenState();
}

class _TautulliGraphsScreenState extends ConsumerState<TautulliGraphsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(tautulliGraphPlaysByDateProvider(widget.instance));
    ref.invalidate(tautulliGraphPlaysByMonthProvider(widget.instance));
    ref.invalidate(tautulliGraphPlaysByDayOfWeekProvider(widget.instance));
    ref.invalidate(tautulliGraphPlaysByTopPlatformsProvider(widget.instance));
    ref.invalidate(tautulliGraphPlaysByTopUsersProvider(widget.instance));
    ref.invalidate(tautulliGraphStreamTypeByDateProvider(widget.instance));
    ref.invalidate(
        tautulliGraphStreamTypeByTopPlatformsProvider(widget.instance));
    ref.invalidate(tautulliGraphStreamTypeByTopUsersProvider(widget.instance));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: const Text('Graphs',
            style: TextStyle(color: AppColors.textOnPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textOnPrimary),
            onPressed: _refresh,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withAlpha(150),
          indicatorColor: AppColors.orangeAccent,
          tabs: const [
            Tab(text: 'Play by Period'),
            Tab(text: 'Stream Info'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PlayByPeriodTab(instance: widget.instance),
          _StreamInfoTab(instance: widget.instance),
        ],
      ),
    );
  }
}

// ── Play by Period tab ────────────────────────────────────────────────────────

class _PlayByPeriodTab extends ConsumerWidget {
  const _PlayByPeriodTab({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.tealPrimary,
      onRefresh: () async {
        ref.invalidate(tautulliGraphPlaysByDateProvider(instance));
        ref.invalidate(tautulliGraphPlaysByMonthProvider(instance));
        ref.invalidate(tautulliGraphPlaysByDayOfWeekProvider(instance));
        ref.invalidate(tautulliGraphPlaysByTopPlatformsProvider(instance));
        ref.invalidate(tautulliGraphPlaysByTopUsersProvider(instance));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _ChartCard(
            title: 'Daily Play Count',
            subtitle: 'Last 30 days — plays per day by media type',
            async: ref.watch(tautulliGraphPlaysByDateProvider(instance)),
            chartBuilder: (data) => _TautulliLineChart(data: data),
          ),
          _ChartCard(
            title: 'Monthly Plays',
            subtitle: 'Last 12 months — plays per month',
            async: ref.watch(tautulliGraphPlaysByMonthProvider(instance)),
            chartBuilder: (data) => _TautulliBarChart(data: data),
          ),
          _ChartCard(
            title: 'Plays by Day of Week',
            subtitle: 'Last 30 days — plays per weekday',
            async:
                ref.watch(tautulliGraphPlaysByDayOfWeekProvider(instance)),
            chartBuilder: (data) => _TautulliBarChart(data: data),
          ),
          _ChartCard(
            title: 'Top Platforms',
            subtitle: 'Last 30 days — plays by platform',
            async:
                ref.watch(tautulliGraphPlaysByTopPlatformsProvider(instance)),
            chartBuilder: (data) =>
                _TautulliBarChart(data: data, rotateLabels: true),
          ),
          _ChartCard(
            title: 'Top Users',
            subtitle: 'Last 30 days — plays by user',
            async: ref.watch(tautulliGraphPlaysByTopUsersProvider(instance)),
            chartBuilder: (data) =>
                _TautulliBarChart(data: data, rotateLabels: true),
          ),
        ],
      ),
    );
  }
}

// ── Stream Info tab ───────────────────────────────────────────────────────────

class _StreamInfoTab extends ConsumerWidget {
  const _StreamInfoTab({required this.instance});
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.tealPrimary,
      onRefresh: () async {
        ref.invalidate(tautulliGraphStreamTypeByDateProvider(instance));
        ref.invalidate(
            tautulliGraphStreamTypeByTopPlatformsProvider(instance));
        ref.invalidate(tautulliGraphStreamTypeByTopUsersProvider(instance));
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _ChartCard(
            title: 'Daily Stream Types',
            subtitle:
                'Last 30 days — direct play, direct stream & transcode',
            async:
                ref.watch(tautulliGraphStreamTypeByDateProvider(instance)),
            chartBuilder: (data) => _TautulliLineChart(data: data),
          ),
          _ChartCard(
            title: 'Stream Types by Platform',
            subtitle: 'Last 30 days — stream type breakdown per platform',
            async: ref.watch(
                tautulliGraphStreamTypeByTopPlatformsProvider(instance)),
            chartBuilder: (data) =>
                _TautulliBarChart(data: data, rotateLabels: true),
          ),
          _ChartCard(
            title: 'Stream Types by User',
            subtitle: 'Last 30 days — stream type breakdown per user',
            async: ref
                .watch(tautulliGraphStreamTypeByTopUsersProvider(instance)),
            chartBuilder: (data) =>
                _TautulliBarChart(data: data, rotateLabels: true),
          ),
        ],
      ),
    );
  }
}

// ── ChartCard ─────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.async,
    required this.chartBuilder,
  });

  final String title;
  final String subtitle;
  final AsyncValue<TautulliGraphData> async;
  final Widget Function(TautulliGraphData) chartBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            async.when(
              loading: () => const _LoadingChart(),
              error: (e, _) => _ErrorChart(message: '$e'),
              data: (data) {
                if (data.isEmpty) {
                  return const _EmptyChart();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 200, child: chartBuilder(data)),
                    const SizedBox(height: 12),
                    _ChartLegend(series: data.series),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Line Chart ────────────────────────────────────────────────────────────────

class _TautulliLineChart extends StatelessWidget {
  const _TautulliLineChart({required this.data});
  final TautulliGraphData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridColor = theme.colorScheme.outlineVariant.withAlpha(80);

    // Show x-axis labels every N points so they don't crowd
    final n = data.categories.length;
    final interval = (n / 5).ceil().toDouble().clamp(1.0, double.infinity);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.categories.length) {
                  return const SizedBox.shrink();
                }
                final label = _shortLabel(data.categories[idx]);
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: data.series.map((s) {
          final color = _seriesColor(s.name);
          return LineChartBarData(
            spots: s.data
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                .toList(),
            color: color,
            barWidth: 2,
            isCurved: true,
            curveSmoothness: 0.3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withAlpha(25),
            ),
          );
        }).toList(),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                theme.colorScheme.surfaceContainerHighest,
            getTooltipItems: (spots) => spots.map((s) {
              final series = data.series[s.barIndex];
              return LineTooltipItem(
                '${series.name}: ${s.y.toInt()}',
                TextStyle(
                    color: _seriesColor(series.name),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ── Bar Chart ─────────────────────────────────────────────────────────────────

class _TautulliBarChart extends StatelessWidget {
  const _TautulliBarChart({required this.data, this.rotateLabels = false});
  final TautulliGraphData data;
  final bool rotateLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gridColor = theme.colorScheme.outlineVariant.withAlpha(80);
    final n = data.categories.length;
    final barWidth = (220.0 / (n * data.series.length)).clamp(4.0, 14.0);

    return BarChart(
      BarChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: rotateLabels ? 40 : 24,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.categories.length) {
                  return const SizedBox.shrink();
                }
                final label = _shortLabel(data.categories[idx]);
                if (rotateLabels) {
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        label,
                        style: TextStyle(
                            fontSize: 9,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.categories.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barsSpace: 2,
            barRods: data.series.map((s) {
              final val = e.key < s.data.length ? s.data[e.key] : 0;
              return BarChartRodData(
                toY: val.toDouble(),
                color: _seriesColor(s.name),
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3)),
              );
            }).toList(),
          );
        }).toList(),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                theme.colorScheme.surfaceContainerHighest,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final series = data.series[rodIndex];
              return BarTooltipItem(
                '${series.name}: ${rod.toY.toInt()}',
                TextStyle(
                    color: _seriesColor(series.name),
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Legend ────────────────────────────────────────────────────────────────────

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.series});
  final List<TautulliGraphSeries> series;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: series.map((s) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _seriesColor(s.name),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${s.name} (${s.total})',
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ── Placeholder states ────────────────────────────────────────────────────────

class _LoadingChart extends StatelessWidget {
  const _LoadingChart();

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
}

class _ErrorChart extends StatelessWidget {
  const _ErrorChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  color: AppColors.statusOffline, size: 28),
              const SizedBox(height: 4),
              Text(message,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.statusOffline),
                  textAlign: TextAlign.center,
                  maxLines: 2),
            ],
          ),
        ),
      );
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No data available',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _seriesColor(String name) {
  return switch (name.toLowerCase().trim()) {
    'tv' || 'television' => AppColors.tealPrimary,
    'movies' || 'movie' => AppColors.orangeAccent,
    'music' => AppColors.blueAccent,
    'direct play' => AppColors.statusOnline,
    'direct stream' => AppColors.statusWarning,
    'transcode' => AppColors.statusOffline,
    _ => const Color(0xFF9B59B6),
  };
}

/// Shortens a date string (e.g. "2024-01-15" → "Jan 15") or returns as-is.
String _shortLabel(String raw) {
  // Try date format YYYY-MM-DD
  final parts = raw.split('-');
  if (parts.length == 3) {
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (month != null && day != null) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      if (month >= 1 && month <= 12) {
        return '${months[month - 1]} $day';
      }
    }
  }
  // Truncate if still long
  return raw.length > 8 ? raw.substring(0, 8) : raw;
}
