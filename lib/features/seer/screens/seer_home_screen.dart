import 'package:flutter/material.dart';

import '../../../core/widgets/module_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/display_mode.dart';
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

class _SeerHomeScreenState extends ConsumerState<SeerHomeScreen> {
  void _openSubScreen(String title, Widget body) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: ModuleAppBar(
            title: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: body,
        ),
      ),
    );
  }

  void _showSortSheet() {
    final current = ref.read(seerDiscoverSortProvider(widget.instance.id));

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.s16),
              child: Text('Sort by', style: Theme.of(ctx).textTheme.titleLarge),
            ),
            const Divider(height: 1),
            Flexible(
              child: RadioGroup<SeerDiscoverSort>(
                groupValue: current,
                onChanged: (val) {
                  if (val != null) {
                    ref
                            .read(
                              seerDiscoverSortProvider(
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
                  children: SeerDiscoverSort.values
                      .map(
                        (opt) => RadioListTile<SeerDiscoverSort>(
                          title: Text(opt.label),
                          value: opt,
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

  @override
  Widget build(BuildContext context) {
    final displayMode = ref.watch(seerDisplayModeProvider(widget.instance.id));
    final mediaType = ref.watch(
      seerDiscoverMediaTypeProvider(widget.instance.id),
    );
    final sort = ref.watch(seerDiscoverSortProvider(widget.instance.id));
    final sortActive = sort != SeerDiscoverSort.popularityDesc;

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Seer',
      sections: [
        ServiceSection(
          label: 'Discover',
          icon: Icons.explore_outlined,
          body: SeerDiscoverScreen(instance: widget.instance),
          toolbar: ServiceToolbar(
            children: [
              TextButton.icon(
                onPressed: _showSortSheet,
                icon: const Icon(Icons.sort),
                label: Text(sortActive ? sort.label : 'Sort'),
              ),
              ChoiceChip(
                label: const Text('Movies'),
                selected: mediaType == 'movie',
                onSelected: (_) =>
                    ref
                            .read(
                              seerDiscoverMediaTypeProvider(
                                widget.instance.id,
                              ).notifier,
                            )
                            .state =
                        'movie',
              ),
              ChoiceChip(
                label: const Text('TV Shows'),
                selected: mediaType == 'tv',
                onSelected: (_) =>
                    ref
                            .read(
                              seerDiscoverMediaTypeProvider(
                                widget.instance.id,
                              ).notifier,
                            )
                            .state =
                        'tv',
              ),
              IconButton(
                icon: Icon(
                  displayMode == DisplayMode.grid
                      ? Icons.view_list_outlined
                      : Icons.grid_view_outlined,
                ),
                tooltip:
                    'Switch to ${displayMode == DisplayMode.grid ? 'List' : 'Grid'}',
                onPressed: () =>
                    ref
                        .read(
                          seerDisplayModeProvider(widget.instance.id).notifier,
                        )
                        .state = displayMode == DisplayMode.grid
                    ? DisplayMode.list
                    : DisplayMode.grid,
              ),
            ],
          ),
        ),
        ServiceSection(
          label: 'Requests',
          icon: Icons.inbox_outlined,
          body: SeerRequestsScreen(instance: widget.instance),
        ),
      ],
      moreItems: const [
        PopupMenuItem(
          value: 'users',
          child: ListTile(
            leading: Icon(Icons.people_outline),
            title: Text('Users'),
          ),
        ),
      ],
      onMoreSelected: (value) {
        if (value == 'users') {
          _openSubScreen('Users', SeerUsersScreen(instance: widget.instance));
        }
      },
    );
  }
}
