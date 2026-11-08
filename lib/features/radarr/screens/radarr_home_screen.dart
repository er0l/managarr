import 'package:flutter/material.dart';

import '../../../core/widgets/module_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../models/radarr_options.dart';
import '../providers/radarr_providers.dart';
import 'radarr_activity_screen.dart';
import 'radarr_queue_screen.dart';
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
                    icon: Icon(
                      ascending ? Icons.arrow_upward : Icons.arrow_downward,
                    ),
                    onPressed: () {
                      ref
                              .read(
                                radarrSortAscendingProvider(
                                  widget.instance.id,
                                ).notifier,
                              )
                              .state =
                          !ascending;
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
                            .read(
                              radarrSortOptionProvider(
                                widget.instance.id,
                              ).notifier,
                            )
                            .state =
                        val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  children: RadarrSortOption.values
                      .map(
                        (o) => RadioListTile<RadarrSortOption>(
                          title: Text(o.label),
                          value: o,
                        ),
                      )
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
    final currentFilter = ref.read(
      radarrFilterOptionProvider(widget.instance.id),
    );
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Text(
                'Filter by',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: RadioGroup<RadarrFilterOption>(
                groupValue: currentFilter,
                onChanged: (val) {
                  if (val != null) {
                    ref
                            .read(
                              radarrFilterOptionProvider(
                                widget.instance.id,
                              ).notifier,
                            )
                            .state =
                        val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: RadarrFilterOption.values
                      .map(
                        (o) => RadioListTile<RadarrFilterOption>(
                          title: Text(o.label),
                          value: o,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
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
          appBar: ModuleAppBar(
            title: Text(
              'History',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: RadarrActivityScreen(instance: widget.instance),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayMode = ref.watch(
      radarrDisplayModeProvider(widget.instance.id),
    );
    final currentSort = ref.watch(radarrSortOptionProvider(widget.instance.id));
    final currentFilter = ref.watch(
      radarrFilterOptionProvider(widget.instance.id),
    );
    final filterActive = currentFilter != RadarrFilterOption.all;
    final sortActive = currentSort != RadarrSortOption.alphabetical;

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Radarr',
      sections: [
        ServiceSection(
          label: 'Library',
          title: 'Movies',
          icon: Icons.video_library_outlined,
          body: RadarrMoviesScreen(instance: widget.instance),
          action: FilledButton.tonalIcon(
            icon: const Icon(Icons.add),
            label: const Text('Add'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RadarrAddMovieScreen(instance: widget.instance),
              ),
            ),
          ),
          toolbar: ServiceToolbar(
            children: [
              TextButton.icon(
                onPressed: _showFilterBottomSheet,
                icon: const Icon(Icons.filter_list),
                label: Text(filterActive ? currentFilter.label : 'Filter'),
              ),
              TextButton.icon(
                onPressed: _showSortBottomSheet,
                icon: const Icon(Icons.sort),
                label: Text(sortActive ? currentSort.label : 'Sort'),
              ),
              IconButton(
                icon: Icon(
                  displayMode == DisplayMode.grid
                      ? Icons.view_list_outlined
                      : Icons.grid_view_outlined,
                ),
                tooltip:
                    'Switch to ${displayMode == DisplayMode.grid ? 'List' : 'Grid'}',
                onPressed: () {
                  ref
                      .read(
                        radarrDisplayModeProvider(widget.instance.id).notifier,
                      )
                      .state = displayMode == DisplayMode.grid
                      ? DisplayMode.list
                      : DisplayMode.grid;
                },
              ),
            ],
          ),
        ),
        ServiceSection(
          label: 'Upcoming',
          icon: Icons.calendar_month_outlined,
          body: RadarrCalendarScreen(instance: widget.instance),
        ),
        ServiceSection(
          label: 'Missing',
          icon: Icons.error_outline,
          body: RadarrMissingScreen(instance: widget.instance),
        ),
      ],
      moreItems: const [
        PopupMenuItem(
          value: 'queue',
          child: ListTile(
            leading: Icon(Icons.download_outlined),
            title: Text('Queue'),
          ),
        ),
        PopupMenuItem(
          value: 'history',
          child: ListTile(leading: Icon(Icons.history), title: Text('History')),
        ),
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
          case 'queue':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: const ModuleAppBar(title: Text('Queue')),
                  body: RadarrQueueScreen(instance: widget.instance),
                ),
              ),
            );
          case 'history':
            _openHistory();
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
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  appBar: ModuleAppBar(
                    title: Text(
                      'Cutoff Unmet',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  body: RadarrCutoffUnmetScreen(instance: widget.instance),
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
