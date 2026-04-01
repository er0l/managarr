import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/service_detail_shell.dart';
import 'nzbget_history_screen.dart';
import 'nzbget_queue_screen.dart';
import 'nzbget_logs_screen.dart';

class NzbgetHomeScreen extends StatefulWidget {
  const NzbgetHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  State<NzbgetHomeScreen> createState() => _NzbgetHomeScreenState();
}

class _NzbgetHomeScreenState extends State<NzbgetHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Queue', 'History', 'Logs'];

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

  @override
  Widget build(BuildContext context) {
    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'NZBGet',
      tabs: _tabs,
      tabController: _tabController,
      tabViews: [
        NzbgetQueueScreen(instance: widget.instance),
        NzbgetHistoryScreen(instance: widget.instance),
        NzbgetLogsScreen(instance: widget.instance),
      ],
    );
  }
}
