import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/service_detail_shell.dart';
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

class _RadarrHomeScreenState extends ConsumerState<RadarrHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Library', 'Upcoming', 'Missing', 'Cutoff', 'Activity'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final displayMode = ref.watch(radarrDisplayModeProvider(widget.instance.id));

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Radarr',
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
                .read(radarrDisplayModeProvider(widget.instance.id).notifier)
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
                _runCommand('RescanMovie', 'Update Library');
              case 'manualImport':
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RadarrManualImportScreen(instance: widget.instance),
                ));
              case 'importLists':
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) =>
                      RadarrImportListsScreen(instance: widget.instance),
                ));
              case 'tags':
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RadarrTagsScreen(instance: widget.instance),
                ));
              case 'systemStatus':
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => RadarrSystemStatusScreen(instance: widget.instance),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orangeAccent,
        foregroundColor: Colors.white,
        tooltip: 'Add Movie',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                RadarrAddMovieScreen(instance: widget.instance),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      tabViews: [
        RadarrMoviesScreen(instance: widget.instance),
        RadarrCalendarScreen(instance: widget.instance),
        RadarrMissingScreen(instance: widget.instance),
        RadarrCutoffUnmetScreen(instance: widget.instance),
        RadarrActivityScreen(instance: widget.instance),
      ],
    );
  }
}
