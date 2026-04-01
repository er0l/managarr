import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../providers/seer_providers.dart';
import 'seer_discover_screen.dart';
import 'seer_requests_screen.dart';
import 'seer_users_screen.dart';

class SeerHomeScreen extends ConsumerStatefulWidget {
  const SeerHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<SeerHomeScreen> createState() => _SeerHomeScreenState();
}

class _SeerHomeScreenState extends ConsumerState<SeerHomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ['Requests', 'Users', 'Discover'];

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
    final displayMode = ref.watch(seerDisplayModeProvider(widget.instance.id));

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Seer',
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
                .read(seerDisplayModeProvider(widget.instance.id).notifier)
                .state = displayMode == DisplayMode.grid
                ? DisplayMode.list
                : DisplayMode.grid;
          },
        ),
      ],
      tabViews: [
        SeerRequestsScreen(instance: widget.instance),
        SeerUsersScreen(instance: widget.instance),
        SeerDiscoverScreen(instance: widget.instance),
      ],
    );
  }
}
