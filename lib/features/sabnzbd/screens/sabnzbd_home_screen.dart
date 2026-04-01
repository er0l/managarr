import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/service_detail_shell.dart';
import 'sabnzbd_history_screen.dart';
import 'sabnzbd_queue_screen.dart';

class SabnzbdHomeScreen extends StatefulWidget {
  const SabnzbdHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  State<SabnzbdHomeScreen> createState() => _SabnzbdHomeScreenState();
}

class _SabnzbdHomeScreenState extends State<SabnzbdHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Queue', 'History'];

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
      serviceName: 'SABnzbd',
      tabs: _tabs,
      tabController: _tabController,
      tabViews: [
        SabnzbdQueueScreen(instance: widget.instance),
        SabnzbdHistoryScreen(instance: widget.instance),
      ],
    );
  }
}
