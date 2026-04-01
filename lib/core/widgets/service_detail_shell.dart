import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../theme/app_colors.dart';
import 'app_drawer.dart';

/// A shared scaffold for service detail modules (Radarr, Sonarr, etc.)
/// that provides a consistent AppBar with title, instance name, and optional tabs.
class ServiceDetailShell extends StatelessWidget {
  const ServiceDetailShell({
    super.key,
    required this.instance,
    required this.serviceName,
    this.tabs = const [],
    required this.tabViews,
    this.actions,
    this.floatingActionButton,
    this.tabController,
  });

  final Instance instance;
  final String serviceName;
  final List<String> tabs;
  final List<Widget> tabViews;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final TabController? tabController;

  @override
  Widget build(BuildContext context) {
    if (tabs.isNotEmpty && tabViews.length != tabs.length) {
      throw ArgumentError('tabs and tabViews must have the same length');
    }

    final scaffold = Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.tealPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textOnPrimary),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              serviceName,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            Text(
              instance.name,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: actions,
        bottom: tabs.isNotEmpty
            ? TabBar(
                controller: tabController,
                indicatorColor: AppColors.orangeAccent,
                indicatorWeight: 3,
                labelColor: AppColors.textOnPrimary,
                unselectedLabelColor: AppColors.textOnPrimary.withAlpha(160),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: tabs.map((t) => Tab(text: t)).toList(),
              )
            : null,
      ),
      body: tabs.isNotEmpty
          ? TabBarView(
              controller: tabController,
              children: tabViews,
            )
          : (tabViews.isNotEmpty ? tabViews.first : const SizedBox.shrink()),
      floatingActionButton: floatingActionButton,
    );

    // If tabs are present but no controller is provided, wrap in DefaultTabController
    if (tabController == null && tabs.isNotEmpty) {
      return DefaultTabController(
        length: tabs.length,
        child: scaffold,
      );
    }

    return scaffold;
  }
}
