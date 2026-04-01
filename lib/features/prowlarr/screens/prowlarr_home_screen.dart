import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/service_detail_shell.dart';
import 'prowlarr_history_screen.dart';
import 'prowlarr_indexers_screen.dart';
import 'prowlarr_search_screen.dart';

class ProwlarrHomeScreen extends StatefulWidget {
  const ProwlarrHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  State<ProwlarrHomeScreen> createState() => _ProwlarrHomeScreenState();
}

class _ProwlarrHomeScreenState extends State<ProwlarrHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Indexers', 'History', 'Search'];

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
      serviceName: 'Prowlarr',
      tabs: _tabs,
      tabController: _tabController,
      tabViews: [
        ProwlarrIndexersScreen(instance: widget.instance),
        ProwlarrHistoryScreen(instance: widget.instance),
        ProwlarrSearchScreen(instance: widget.instance),
      ],
    );
  }
}
