import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/service_detail_shell.dart';
import 'tautulli_activity_screen.dart';
import 'tautulli_history_screen.dart';
import 'tautulli_libraries_screen.dart';
import 'tautulli_graphs_screen.dart';
import 'tautulli_recently_added_screen.dart';
import 'tautulli_statistics_screen.dart';
import 'tautulli_users_screen.dart';

class TautulliHomeScreen extends StatefulWidget {
  const TautulliHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  State<TautulliHomeScreen> createState() => _TautulliHomeScreenState();
}

class _TautulliHomeScreenState extends State<TautulliHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    'Activity',
    'History',
    'Libraries',
    'Users',
    'Recent',
  ];

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

  void _openStatistics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TautulliStatisticsScreen(instance: widget.instance),
      ),
    );
  }

  void _openGraphs() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TautulliGraphsScreen(instance: widget.instance),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Tautulli',
      tabs: _tabs,
      tabController: _tabController,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'graphs') _openGraphs();
            if (value == 'statistics') _openStatistics();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'graphs',
              child: ListTile(
                leading: Icon(Icons.bar_chart_outlined),
                title: Text('Graphs'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: 'statistics',
              child: ListTile(
                leading: Icon(Icons.leaderboard_outlined),
                title: Text('Statistics'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
      tabViews: [
        TautulliActivityScreen(instance: widget.instance),
        TautulliHistoryScreen(instance: widget.instance),
        TautulliLibrariesScreen(instance: widget.instance),
        TautulliUsersScreen(instance: widget.instance),
        TautulliRecentlyAddedScreen(instance: widget.instance),
      ],
    );
  }
}
