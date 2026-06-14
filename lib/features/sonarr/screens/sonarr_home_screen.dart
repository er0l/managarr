import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/config/byte_formatter.dart';
import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../api/models/series.dart';
import '../models/sonarr_options.dart';
import '../providers/sonarr_providers.dart';
import 'sonarr_activity_screen.dart';
import 'sonarr_add_series_screen.dart';
import 'sonarr_calendar_screen.dart';
import 'sonarr_cutoff_unmet_screen.dart';
import 'sonarr_missing_screen.dart';
import 'sonarr_series_detail_screen.dart';
import 'sonarr_manual_import_screen.dart';
import 'sonarr_import_lists_screen.dart';
import 'sonarr_system_status_screen.dart';
import 'sonarr_tags_screen.dart';

class SonarrHomeScreen extends ConsumerStatefulWidget {
  const SonarrHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SonarrHomeScreen> createState() => _SonarrHomeScreenState();
}

class _SonarrHomeScreenState extends ConsumerState<SonarrHomeScreen> {
  Future<void> _runCommand(String name, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      await api.sendCommand(name);
      messenger.showSnackBar(SnackBar(
        content: Text('$label started'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showSortBottomSheet() {
    final currentSort =
        ref.read(sonarrSortOptionProvider(widget.instance.id));
    final ascending =
        ref.read(sonarrSortAscendingProvider(widget.instance.id));
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Row(
                children: [
                  Text('Sort by', style: Theme.of(ctx).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: Icon(ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward),
                    onPressed: () {
                      ref
                          .read(sonarrSortAscendingProvider(
                                  widget.instance.id)
                              .notifier)
                          .state = !ascending;
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: RadioGroup<SonarrSortOption>(
                groupValue: currentSort,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(sonarrSortOptionProvider(widget.instance.id)
                            .notifier)
                        .state = val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  children: SonarrSortOption.values
                      .map((o) => RadioListTile<SonarrSortOption>(
                            title: Text(o.label),
                            value: o,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    final currentFilter =
        ref.read(sonarrFilterOptionProvider(widget.instance.id));
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Text('Filter by',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: RadioGroup<SonarrFilterOption>(
                groupValue: currentFilter,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(sonarrFilterOptionProvider(widget.instance.id)
                            .notifier)
                        .state = val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: SonarrFilterOption.values
                      .map((o) => RadioListTile<SonarrFilterOption>(
                            title: Text(o.label),
                            value: o,
                          ))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openUpcoming() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Upcoming',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: SonarrCalendarScreen(instance: widget.instance),
        ),
      ),
    );
  }

  void _openMissing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Missing',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: SonarrMissingScreen(instance: widget.instance),
        ),
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'History',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: SonarrActivityScreen(instance: widget.instance),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMode =
        ref.watch(sonarrDisplayModeProvider(widget.instance.id));
    final currentSort =
        ref.watch(sonarrSortOptionProvider(widget.instance.id));
    final currentFilter =
        ref.watch(sonarrFilterOptionProvider(widget.instance.id));
    final filterActive = currentFilter != SonarrFilterOption.all;
    final sortActive = currentSort != SonarrSortOption.alphabetical;

    const muted = Color(0xA0FFFFFF);

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Sonarr',
      tabs: const [],
      tabViews: [SonarrSeriesScreen(instance: widget.instance)],
      floatingActionButton: FloatingActionButton(
        backgroundColor: ServiceType.sonarr.brandColor,
        foregroundColor: Colors.white,
        tooltip: 'Add Series',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SonarrAddSeriesScreen(instance: widget.instance),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      appBarActions: [
        IconButton(
          icon: Icon(
            displayMode == DisplayMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
            color: Colors.white,
          ),
          tooltip:
              'Switch to ${displayMode == DisplayMode.grid ? 'List' : 'Grid'}',
          onPressed: () {
            ref
                .read(sonarrDisplayModeProvider(widget.instance.id).notifier)
                .state = displayMode == DisplayMode.grid
                ? DisplayMode.list
                : DisplayMode.grid;
          },
        ),
      ],
      bottomLeadingActions: [
        IconButton(
          icon: Icon(Icons.filter_list,
              color: filterActive ? AppColors.tealPrimary : muted),
          tooltip: 'Filter',
          onPressed: _showFilterBottomSheet,
        ),
        IconButton(
          icon: Icon(Icons.sort,
              color: sortActive ? AppColors.tealPrimary : muted),
          tooltip: 'Sort',
          onPressed: _showSortBottomSheet,
        ),
        IconButton(
          icon: const Icon(Icons.history, color: muted),
          tooltip: 'History',
          onPressed: _openHistory,
        ),
      ],
      bottomTrailingActions: [
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined, color: muted),
          tooltip: 'Upcoming',
          onPressed: _openUpcoming,
        ),
        IconButton(
          icon: const Icon(Icons.video_file_outlined, color: muted),
          tooltip: 'Missing',
          onPressed: _openMissing,
        ),
      ],
      bottomMoreItems: const [
        PopupMenuItem(
          value: 'updateLibrary',
          child: ListTile(
            leading: Icon(Icons.folder_open_outlined),
            title: Text('Update Library'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'manualImport',
          child: ListTile(
            leading: Icon(Icons.drive_folder_upload_outlined),
            title: Text('Manual Import'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'importLists',
          child: ListTile(
            leading: Icon(Icons.list_alt_outlined),
            title: Text('Import Lists'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'cutoff',
          child: ListTile(
            leading: Icon(Icons.hd_outlined),
            title: Text('Cutoff Unmet'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'tags',
          child: ListTile(
            leading: Icon(Icons.label_outline),
            title: Text('Tags'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'systemStatus',
          child: ListTile(
            leading: Icon(Icons.monitor_heart_outlined),
            title: Text('System Status'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      onMoreSelected: (value) {
        switch (value) {
          case 'updateLibrary':
            _runCommand('RescanSeries', 'Update Library');
          case 'manualImport':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SonarrManualImportScreen(instance: widget.instance),
              ),
            );
          case 'importLists':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SonarrImportListsScreen(instance: widget.instance),
              ),
            );
          case 'cutoff':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  backgroundColor:
                      Theme.of(context).scaffoldBackgroundColor,
                  appBar: AppBar(
                    backgroundColor: AppColors.tealPrimary,
                    iconTheme: const IconThemeData(color: Colors.white),
                    title: const Text(
                      'Cutoff Unmet',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  body: SonarrCutoffUnmetScreen(instance: widget.instance),
                ),
              ),
            );
          case 'tags':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SonarrTagsScreen(instance: widget.instance),
              ),
            );
          case 'systemStatus':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    SonarrSystemStatusScreen(instance: widget.instance),
              ),
            );
        }
      },
    );
  }
}

// ---------------------------------------------------------------------------

class SonarrSeriesScreen extends ConsumerStatefulWidget {
  const SonarrSeriesScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SonarrSeriesScreen> createState() =>
      _SonarrSeriesScreenState();
}

class _SonarrSeriesScreenState extends ConsumerState<SonarrSeriesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text =
          ref.read(sonarrSearchQueryProvider(widget.instance.id));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(sonarrSeriesProvider(widget.instance));
    final filteredSeries =
        ref.watch(sonarrFilteredSeriesProvider(widget.instance));
    final displayMode =
        ref.watch(sonarrDisplayModeProvider(widget.instance.id));
    final query = ref.watch(sonarrSearchQueryProvider(widget.instance.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.pageHorizontal,
            Spacing.s12,
            Spacing.pageHorizontal,
            Spacing.s8,
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: seriesAsync.value?.length != null
                  ? 'Search ${seriesAsync.value!.length} series…'
                  : 'Search series…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(sonarrSearchQueryProvider(
                                    widget.instance.id)
                                .notifier)
                            .state = '';
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
            onChanged: (v) => ref
                .read(
                    sonarrSearchQueryProvider(widget.instance.id).notifier)
                .state = v,
          ),
        ),
        Expanded(
          child: seriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off,
                      size: 48, color: AppColors.statusOffline),
                  const SizedBox(height: Spacing.s12),
                  Text(
                    'Could not connect',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Spacing.s8),
                  FilledButton.icon(
                    onPressed: () =>
                        ref.invalidate(sonarrSeriesProvider(widget.instance)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tealPrimary,
                      shape: const StadiumBorder(),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (_) {
              if (filteredSeries.isEmpty) {
                return Center(
                  child: Text(
                    query.isNotEmpty
                        ? 'No results for "$query"'
                        : 'No series found',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                );
              }
              return RefreshIndicator(
                color: AppColors.tealPrimary,
                onRefresh: () async =>
                    ref.invalidate(sonarrSeriesProvider(widget.instance)),
                child: displayMode == DisplayMode.grid
                    ? _SeriesGrid(
                        series: filteredSeries,
                        instance: widget.instance)
                    : _SeriesList(
                        series: filteredSeries,
                        instance: widget.instance),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Grid ────────────────────────────────────────────────────────────────────

class _SeriesGrid extends StatelessWidget {
  const _SeriesGrid({required this.series, required this.instance});
  final List<SonarrSeries> series;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        Spacing.pageHorizontal,
        0,
        Spacing.pageHorizontal,
        Spacing.s24,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
        crossAxisSpacing: Spacing.cardGap,
        mainAxisSpacing: Spacing.cardGap,
        childAspectRatio: 0.62,
      ),
      itemCount: series.length,
      itemBuilder: (context, index) =>
          _SeriesGridCard(series: series[index], instance: instance),
    );
  }
}

class _SeriesGridCard extends StatelessWidget {
  const _SeriesGridCard({required this.series, required this.instance});
  final SonarrSeries series;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final posterUrl = series.posterUrl;
    final isUnmonitored = !series.monitored &&
        (series.statistics?.percentOfEpisodes ?? 100.0) < 100.0;

    return Opacity(
      opacity: isUnmonitored ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SonarrSeriesDetailScreen(series: series, instance: instance),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Hero(
                tag: 'sonarr-poster-${series.id}',
                child: posterUrl != null
                    ? Image.network(posterUrl, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.tealDark,
                        alignment: Alignment.center,
                        child: Text(
                          series.title.isNotEmpty ? series.title[0] : 'S',
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (series.year != null && series.year! > 0)
                        Text(
                          series.year.toString(),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                    ],
                  ),
                ),
              ),
              // Status dot
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: switch (series.status) {
                      'continuing' => AppColors.statusOnline,
                      'ended' => AppColors.statusOffline,
                      _ => AppColors.statusUnknown,
                    },
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── List ────────────────────────────────────────────────────────────────────

class _SeriesList extends StatelessWidget {
  const _SeriesList({required this.series, required this.instance});
  final List<SonarrSeries> series;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: Spacing.s24),
      itemCount: series.length,
      itemBuilder: (context, index) =>
          _SeriesTile(series: series[index], instance: instance),
    );
  }
}

String _formatRuntime(int? minutes) {
  if (minutes == null || minutes <= 0) return '';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

String _formatSeriesStatus(String? status) {
  if (status == null || status.isEmpty) return '';
  switch (status.toLowerCase()) {
    case 'continuing':
      return 'Continuing';
    case 'ended':
      return 'Ended';
    case 'upcoming':
      return 'Upcoming';
    default:
      return status[0].toUpperCase() + status.substring(1);
  }
}

class _SeriesTile extends ConsumerWidget {
  const _SeriesTile({required this.series, required this.instance});

  final SonarrSeries series;
  final Instance instance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final posterUrl = series.posterUrl;
    final fanartUrl = series.fanartUrl;
    final accentColor = ServiceType.sonarr.brandColor;

    final profilesAsync =
        ref.watch(sonarrQualityProfilesProvider(instance));
    final profileName = profilesAsync.valueOrNull
        ?.where((p) => p.id == series.qualityProfileId)
        .map((p) => p.name)
        .firstOrNull;

    final cardBg =
        isDark ? const Color(0xFF141E2E) : const Color(0xFFF2F4F7);

    final sizeOnDisk = series.statistics?.sizeOnDisk ?? 0;
    final episodeFileCount = series.statistics?.episodeFileCount ?? 0;
    final episodeCount = series.statistics?.episodeCount ?? 0;

    final isUnmonitored = !series.monitored &&
        (series.statistics?.percentOfEpisodes ?? 100.0) < 100.0;

    final line2Parts = [
      if (series.year != null && series.year! > 0) '${series.year}',
      if (series.runtime != null && series.runtime! > 0)
        _formatRuntime(series.runtime),
      if (series.network != null && series.network!.isNotEmpty)
        series.network!,
    ];

    final line3Parts = [
      if (profileName != null && profileName.isNotEmpty) profileName,
      _formatSeriesStatus(series.status),
      if (series.added != null)
        'Added ${DateFormat('MMM y').format(series.added!)}',
    ].where((s) => s.isNotEmpty).toList();

    return Opacity(
      opacity: isUnmonitored ? 0.55 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.pageHorizontal,
          vertical: 4,
        ),
        child: Material(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SonarrSeriesDetailScreen(
                    series: series,
                    instance: instance,
                  ),
                ),
              );
            },
            child: SizedBox(
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (fanartUrl != null)
                    Positioned.fill(
                      child: Image.network(
                        fanartUrl,
                        fit: BoxFit.cover,
                        color: Colors.black
                            .withAlpha(isDark ? 184 : 210),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, e, st) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            cardBg,
                            cardBg.withAlpha(isDark ? 200 : 230),
                            cardBg.withAlpha(isDark ? 120 : 160),
                          ],
                          stops: const [0, 0.55, 1],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // Poster
                        Hero(
                          tag: 'sonarr-poster-${series.id}',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 60,
                              height: 88,
                              child: posterUrl != null
                                  ? Image.network(posterUrl,
                                      fit: BoxFit.cover)
                                  : Container(
                                      color: AppColors.tealDark,
                                      alignment: Alignment.center,
                                      child: Text(
                                        series.title.isNotEmpty
                                            ? series.title[0]
                                            : 'S',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Text content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Line 1: Title
                              Text(
                                series.title,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              // Line 2: Year · Runtime · Network
                              Text(
                                line2Parts.join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              // Line 3: Profile · Status · DateAdded
                              Text(
                                line3Parts.join(' · '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary
                                      .withAlpha(200),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              // Line 4: icons + size + episodes
                              Row(
                                children: [
                                  Icon(
                                    series.monitored
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    size: 14,
                                    color: series.monitored
                                        ? accentColor
                                        : AppColors.textSecondary,
                                  ),
                                  if ((series.statistics
                                              ?.percentOfEpisodes ??
                                          0) >=
                                      100) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 14,
                                      color: AppColors.statusOnline,
                                    ),
                                  ],
                                  const Spacer(),
                                  if (sizeOnDisk > 0) ...[
                                    _Chip(
                                      label: ByteFormatter.format(
                                          sizeOnDisk),
                                      color: AppColors.statusOnline,
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  if (episodeCount > 0)
                                    _Chip(
                                      label:
                                          '$episodeFileCount/$episodeCount ep',
                                      color: accentColor,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(70), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}
