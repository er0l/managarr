import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../models/radarr_options.dart';
import '../providers/radarr_providers.dart';
import 'radarr_activity_screen.dart';
import 'radarr_add_movie_screen.dart';
import 'radarr_calendar_screen.dart';
import 'radarr_cutoff_unmet_screen.dart';
import 'radarr_missing_screen.dart';
import 'radarr_movies_screen.dart';
import 'radarr_manual_import_screen.dart';
import 'radarr_import_lists_screen.dart';
import 'radarr_system_status_screen.dart';
import 'radarr_tags_screen.dart';

class RadarrHomeScreen extends ConsumerStatefulWidget {
  const RadarrHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<RadarrHomeScreen> createState() => _RadarrHomeScreenState();
}

class _RadarrHomeScreenState extends ConsumerState<RadarrHomeScreen> {
  Future<void> _runCommand(String name, String label) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final api = ref.read(radarrApiProvider(widget.instance));
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
    final currentSort = ref.read(radarrSortOptionProvider(widget.instance.id));
    final ascending = ref.read(radarrSortAscendingProvider(widget.instance.id));
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
                          .read(radarrSortAscendingProvider(widget.instance.id)
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
              child: RadioGroup<RadarrSortOption>(
                groupValue: currentSort,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(radarrSortOptionProvider(widget.instance.id)
                            .notifier)
                        .state = val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  children: RadarrSortOption.values
                      .map((o) => RadioListTile<RadarrSortOption>(
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
        ref.read(radarrFilterOptionProvider(widget.instance.id));
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
              child: RadioGroup<RadarrFilterOption>(
                groupValue: currentFilter,
                onChanged: (val) {
                  if (val != null) {
                    ref
                        .read(radarrFilterOptionProvider(widget.instance.id)
                            .notifier)
                        .state = val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: RadarrFilterOption.values
                      .map((o) => RadioListTile<RadarrFilterOption>(
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: RadarrCalendarScreen(instance: widget.instance),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: RadarrMissingScreen(instance: widget.instance),
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
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          body: RadarrActivityScreen(instance: widget.instance),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMode =
        ref.watch(radarrDisplayModeProvider(widget.instance.id));
    final currentSort =
        ref.watch(radarrSortOptionProvider(widget.instance.id));
    final currentFilter =
        ref.watch(radarrFilterOptionProvider(widget.instance.id));
    final filterActive = currentFilter != RadarrFilterOption.all;
    final sortActive = currentSort != RadarrSortOption.alphabetical;

    const muted = Color(0xA0FFFFFF);

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Radarr',
      tabs: const [],
      tabViews: [RadarrMoviesScreen(instance: widget.instance)],
      floatingActionButton: FloatingActionButton(
        backgroundColor: ServiceType.radarr.brandColor,
        foregroundColor: Colors.black,
        tooltip: 'Add Movie',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RadarrAddMovieScreen(instance: widget.instance),
          ),
        ),
        child: const Icon(Icons.add),
      ),
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
        IconButton(
          icon: Icon(
            displayMode == DisplayMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
            color: muted,
          ),
          tooltip:
              'Switch to ${displayMode == DisplayMode.grid ? 'List' : 'Grid'}',
          onPressed: () {
            ref
                .read(radarrDisplayModeProvider(widget.instance.id).notifier)
                .state = displayMode == DisplayMode.grid
                ? DisplayMode.list
                : DisplayMode.grid;
          },
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
            _runCommand('RescanMovie', 'Update Library');
          case 'manualImport':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RadarrManualImportScreen(instance: widget.instance),
              ),
            );
          case 'importLists':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RadarrImportListsScreen(instance: widget.instance),
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
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  body: RadarrCutoffUnmetScreen(
                      instance: widget.instance),
                ),
              ),
            );
          case 'tags':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RadarrTagsScreen(instance: widget.instance),
              ),
            );
          case 'systemStatus':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RadarrSystemStatusScreen(instance: widget.instance),
              ),
            );
        }
      },
    );
  }
}
