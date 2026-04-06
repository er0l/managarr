import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
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

class _SonarrHomeScreenState extends ConsumerState<SonarrHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;

  static const _tabs = ['Library', 'Calendar', 'Missing', 'Cutoff', 'Activity'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runCommand(String name, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(sonarrApiProvider(widget.instance));
      await api.sendCommand(name);
      messenger.showSnackBar(
        SnackBar(
          content: Text('$label started'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayMode = ref.watch(sonarrDisplayModeProvider(widget.instance.id));

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Sonarr',
      tabs: _tabs,
      tabController: _tabController,
      actions: [
        IconButton(
          icon: Icon(
            displayMode == DisplayMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
            color: AppColors.textOnPrimary,
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
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textOnPrimary),
          onSelected: (value) {
            switch (value) {
              case 'updateLibrary':
                _runCommand('RescanSeries', 'Update Library');
              case 'manualImport':
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SonarrManualImportScreen(instance: widget.instance),
                ));
              case 'importLists':
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) =>
                      SonarrImportListsScreen(instance: widget.instance),
                ));
              case 'tags':
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SonarrTagsScreen(instance: widget.instance),
                ));
              case 'systemStatus':
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => SonarrSystemStatusScreen(instance: widget.instance),
                ));
            }
          },
          itemBuilder: (context) => const [
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
        ),
      ],
      tabViews: [
        SonarrSeriesScreen(instance: widget.instance),
        SonarrCalendarScreen(instance: widget.instance),
        SonarrMissingScreen(instance: widget.instance),
        SonarrCutoffUnmetScreen(instance: widget.instance),
        SonarrActivityScreen(instance: widget.instance),
      ],
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.orangeAccent,
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
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------

class SonarrSeriesScreen extends ConsumerStatefulWidget {
  const SonarrSeriesScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SonarrSeriesScreen> createState() => _SonarrSeriesScreenState();
}

class _SonarrSeriesScreenState extends ConsumerState<SonarrSeriesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchController.text = ref.read(sonarrSearchQueryProvider(widget.instance.id));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSortBottomSheet() {
    final currentSort = ref.read(sonarrSortOptionProvider(widget.instance.id));
    final ascending = ref.read(sonarrSortAscendingProvider(widget.instance.id));

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Row(
                children: [
                  Text('Sort by', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: Icon(ascending ? Icons.arrow_upward : Icons.arrow_downward),
                    onPressed: () {
                      ref.read(sonarrSortAscendingProvider(widget.instance.id).notifier).state = !ascending;
                      Navigator.pop(context);
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
                    ref.read(sonarrSortOptionProvider(widget.instance.id).notifier).state = val;
                    Navigator.pop(context);
                  }
                },
                child: ListView(
                  children: SonarrSortOption.values
                      .map((option) => RadioListTile<SonarrSortOption>(
                            title: Text(option.label),
                            value: option,
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
    final currentFilter = ref.read(sonarrFilterOptionProvider(widget.instance.id));

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Text('Filter by', style: Theme.of(context).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: RadioGroup<SonarrFilterOption>(
                groupValue: currentFilter,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(sonarrFilterOptionProvider(widget.instance.id).notifier).state = val;
                    Navigator.pop(context);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: SonarrFilterOption.values
                      .map((option) => RadioListTile<SonarrFilterOption>(
                            title: Text(option.label),
                            value: option,
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

  @override
  Widget build(BuildContext context) {
    final seriesAsync = ref.watch(sonarrSeriesProvider(widget.instance));
    final filteredSeries = ref.watch(sonarrFilteredSeriesProvider(widget.instance));
    final displayMode = ref.watch(sonarrDisplayModeProvider(widget.instance.id));
    final query = ref.watch(sonarrSearchQueryProvider(widget.instance.id));
    final currentSort = ref.watch(sonarrSortOptionProvider(widget.instance.id));
    final currentFilter = ref.watch(sonarrFilterOptionProvider(widget.instance.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.pageHorizontal, Spacing.s12,
            Spacing.pageHorizontal, Spacing.s8,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search series…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(sonarrSearchQueryProvider(widget.instance.id).notifier).state = '';
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (v) => ref.read(sonarrSearchQueryProvider(widget.instance.id).notifier).state = v,
                ),
              ),
              const SizedBox(width: Spacing.s8),
              _ControlButton(
                icon: Icons.filter_list,
                isActive: currentFilter != SonarrFilterOption.all,
                onTap: _showFilterBottomSheet,
              ),
              const SizedBox(width: Spacing.s4),
              _ControlButton(
                icon: Icons.sort,
                isActive: currentSort != SonarrSortOption.alphabetical,
                onTap: _showSortBottomSheet,
              ),
            ],
          ),
        ),
        Expanded(
          child: seriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48, color: AppColors.statusOffline),
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
                    query.isNotEmpty ? 'No results for "$query"' : 'No series found',
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
                    ? _SeriesGrid(series: filteredSeries, instance: widget.instance)
                    : _SeriesList(series: filteredSeries, instance: widget.instance),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton.filledTonal(
      onPressed: onTap,
      iconSize: 20,
      style: IconButton.styleFrom(
        backgroundColor: isActive ? colorScheme.primaryContainer : null,
        foregroundColor: isActive ? colorScheme.onPrimaryContainer : null,
      ),
      icon: Icon(icon),
    );
  }
}

class _SeriesGrid extends StatelessWidget {
  const _SeriesGrid({required this.series, required this.instance});
  final List<SonarrSeries> series;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        Spacing.pageHorizontal, 0,
        Spacing.pageHorizontal, Spacing.s24,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SonarrSeriesDetailScreen(
              series: series,
              instance: instance,
            ),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (posterUrl != null)
              Image.network(posterUrl, fit: BoxFit.cover)
            else
              Container(
                color: AppColors.tealDark,
                alignment: Alignment.center,
                child: Text(
                  series.title[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(200),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Title
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                series.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

class _SeriesTile extends StatelessWidget {
  const _SeriesTile({required this.series, required this.instance});

  final SonarrSeries series;
  final Instance instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = series.posterUrl;
    final statusColor = switch (series.status) {
      'continuing' => AppColors.statusOnline,
      'ended' => AppColors.statusOffline,
      _ => AppColors.statusUnknown,
    };

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Spacing.pageHorizontal, vertical: 4),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SonarrSeriesDetailScreen(
            series: series,
            instance: instance,
          ),
        ),
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
                  child: Text(
                    series.title.isNotEmpty ? series.title[0] : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
        ),
      ),
      title: Text(
        series.title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6, top: 1),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          Text(
            [
              if (series.status != null)
                series.status![0].toUpperCase() + series.status!.substring(1),
              if (series.seasonCount != null)
                '${series.seasonCount} season${series.seasonCount == 1 ? '' : 's'}',
            ].join(' · '),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
      trailing: series.monitored
          ? null
          : const Icon(Icons.visibility_off_outlined,
              size: 18, color: AppColors.statusUnknown),
    );
  }
}
