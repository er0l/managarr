import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/widgets/module_app_bar.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../providers/tautulli_providers.dart';
import 'tautulli_activity_screen.dart';
import 'tautulli_graphs_screen.dart';
import 'tautulli_history_screen.dart';
import 'tautulli_libraries_screen.dart';
import 'tautulli_recently_added_screen.dart';
import 'tautulli_statistics_screen.dart';
import 'tautulli_users_screen.dart';

class TautulliHomeScreen extends ConsumerWidget {
  const TautulliHomeScreen({super.key, required this.instance});
  final Instance instance;

  void _open(BuildContext context, Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context, WidgetRef ref) => ServiceDetailShell(
    instance: instance,
    serviceName: 'Tautulli',
    sections: [
      ServiceSection(
        label: 'Activity',
        icon: Icons.sensors_outlined,
        body: TautulliActivityScreen(instance: instance),
        action: IconButton(
          tooltip: 'Refresh activity',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(tautulliActivityProvider(instance)),
        ),
      ),
      ServiceSection(
        label: 'History',
        icon: Icons.history,
        body: TautulliHistoryScreen(instance: instance),
      ),
      ServiceSection(
        label: 'Libraries',
        icon: Icons.video_library_outlined,
        body: TautulliLibrariesScreen(instance: instance),
      ),
    ],
    moreItems: const [
      PopupMenuItem(
        value: 'recent',
        child: ListTile(
          leading: Icon(Icons.fiber_new_outlined),
          title: Text('Recently added'),
        ),
      ),
      PopupMenuItem(
        value: 'users',
        child: ListTile(
          leading: Icon(Icons.people_outline),
          title: Text('Users'),
        ),
      ),
      PopupMenuDivider(),
      PopupMenuItem(
        value: 'graphs',
        child: ListTile(
          leading: Icon(Icons.bar_chart_outlined),
          title: Text('Graphs'),
        ),
      ),
      PopupMenuItem(
        value: 'statistics',
        child: ListTile(
          leading: Icon(Icons.leaderboard_outlined),
          title: Text('Statistics'),
        ),
      ),
    ],
    onMoreSelected: (value) {
      switch (value) {
        case 'recent':
          _open(context, _RecentlyAddedPage(instance: instance));
        case 'users':
          _open(
            context,
            Scaffold(
              appBar: const ModuleAppBar(title: Text('Users')),
              body: TautulliUsersScreen(instance: instance),
            ),
          );
        case 'graphs':
          _open(context, TautulliGraphsScreen(instance: instance));
        case 'statistics':
          _open(context, TautulliStatisticsScreen(instance: instance));
      }
    },
  );
}

class _RecentlyAddedPage extends StatefulWidget {
  const _RecentlyAddedPage({required this.instance});
  final Instance instance;
  @override
  State<_RecentlyAddedPage> createState() => _RecentlyAddedPageState();
}

class _RecentlyAddedPageState extends State<_RecentlyAddedPage> {
  String? _filter;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const ModuleAppBar(title: Text('Recently added')),
    body: Column(
      children: [
        ServiceToolbar(
          children: [
            for (final option in <(String, String?)>[
              ('All', null),
              ('Movies', 'movie'),
              ('TV', 'episode'),
              ('Music', 'track'),
            ])
              ChoiceChip(
                label: Text(option.$1),
                selected: _filter == option.$2,
                onSelected: (_) => setState(() => _filter = option.$2),
              ),
          ],
        ),
        Expanded(
          child: TautulliRecentlyAddedScreen(
            instance: widget.instance,
            mediaTypeFilter: _filter,
          ),
        ),
      ],
    ),
  );
}
