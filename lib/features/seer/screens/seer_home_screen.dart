import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/spacing.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/models/display_mode.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/service_detail_shell.dart';
import '../providers/seer_providers.dart';
import 'seer_discover_screen.dart';
import 'seer_requests_screen.dart';
import 'seer_users_screen.dart';

/// Seer module home — Discover is the main body (Radarr/Sonarr layout).
/// Requests and Users open as full screens from the bottom bar; media type
/// (Movies/TV) and sort live in the bottom bar; grid/list toggle top-right.
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
          appBar: AppBar(
            backgroundColor: AppColors.tealPrimary,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              title,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
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
                        .read(seerDiscoverSortProvider(widget.instance.id)
                            .notifier)
                        .state = val;
                    Navigator.pop(ctx);
                  }
                },
                child: ListView(
                  shrinkWrap: true,
                  children: SeerDiscoverSort.values
                      .map((opt) => RadioListTile<SeerDiscoverSort>(
                            title: Text(opt.label),
                            value: opt,
                          ))
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
    final mediaType =
        ref.watch(seerDiscoverMediaTypeProvider(widget.instance.id));
    final sort = ref.watch(seerDiscoverSortProvider(widget.instance.id));
    final sortActive = sort != SeerDiscoverSort.popularityDesc;

    const muted = Color(0xA0FFFFFF);

    return ServiceDetailShell(
      instance: widget.instance,
      serviceName: 'Seer',
      tabs: const [],
      tabViews: [SeerDiscoverScreen(instance: widget.instance)],
      appBarActions: [
        IconButton(
          icon: Icon(
            displayMode == DisplayMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
            color: Colors.white,
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: ServiceType.seer.brandColor,
        foregroundColor: Colors.white,
        tooltip: 'Requests',
        onPressed: () => _openSubScreen(
          'Requests',
          SeerRequestsScreen(instance: widget.instance),
        ),
        child: const Icon(Icons.playlist_add_check_outlined),
      ),
      bottomLeadingActions: [
        IconButton(
          icon: Icon(
            Icons.movie_outlined,
            color: mediaType == 'movie' ? AppColors.tealPrimary : muted,
          ),
          tooltip: 'Movies',
          onPressed: () => ref
              .read(seerDiscoverMediaTypeProvider(widget.instance.id).notifier)
              .state = 'movie',
        ),
        IconButton(
          icon: Icon(
            Icons.tv_outlined,
            color: mediaType == 'tv' ? AppColors.tealPrimary : muted,
          ),
          tooltip: 'TV Shows',
          onPressed: () => ref
              .read(seerDiscoverMediaTypeProvider(widget.instance.id).notifier)
              .state = 'tv',
        ),
        IconButton(
          icon: Icon(Icons.sort,
              color: sortActive ? AppColors.tealPrimary : muted),
          tooltip: 'Sort',
          onPressed: _showSortSheet,
        ),
      ],
      bottomTrailingActions: [
        IconButton(
          icon: const Icon(Icons.people_outline, color: muted),
          tooltip: 'Users',
          onPressed: () => _openSubScreen(
            'Users',
            SeerUsersScreen(instance: widget.instance),
          ),
        ),
      ],
    );
  }
}
