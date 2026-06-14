import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/models/service_type.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_drawer.dart';
import '../providers/tautulli_providers.dart';
import 'tautulli_activity_screen.dart';
import 'tautulli_graphs_screen.dart';
import 'tautulli_history_screen.dart';
import 'tautulli_libraries_screen.dart';
import 'tautulli_recently_added_screen.dart';
import 'tautulli_statistics_screen.dart';
import 'tautulli_users_screen.dart';

class TautulliHomeScreen extends ConsumerStatefulWidget {
  const TautulliHomeScreen({super.key, required this.instance});

  final Instance instance;

  @override
  ConsumerState<TautulliHomeScreen> createState() => _TautulliHomeScreenState();
}

class _TautulliHomeScreenState extends ConsumerState<TautulliHomeScreen> {
  int _selectedIndex = 0;
  String? _recentFilter; // null=All, 'movie', 'episode', 'track'

  static const _navItems = [
    (Icons.sensors_outlined, 'Activity'),
    (Icons.history_outlined, 'History'),
    (Icons.video_library_outlined, 'Libraries'),
    (Icons.people_outline, 'Users'),
    (Icons.fiber_new_outlined, 'Recent'),
  ];

  void _reload() {
    switch (_selectedIndex) {
      case 0:
        ref.invalidate(tautulliActivityProvider(widget.instance));
      case 1:
        ref.invalidate(tautulliHistoryProvider(widget.instance));
      case 2:
        ref.invalidate(tautulliLibrariesProvider(widget.instance));
      case 3:
        ref.invalidate(tautulliUsersProvider(widget.instance));
      case 4:
        ref.invalidate(tautulliRecentlyAddedProvider(widget.instance));
    }
  }

  @override
  Widget build(BuildContext context) {
    final instance = widget.instance;
    final hasLocalUrl =
        instance.localUrl != null && instance.localUrl!.isNotEmpty;
    final useLocal =
        hasLocalUrl ? ref.watch(useLocalUrlProvider(instance.id)) : false;

    const fgColor = Colors.white;
    const muted = Color(0xA0FFFFFF);

    // ── AppBar ────────────────────────────────────────────────────────────────
    final appBar = AppBar(
      backgroundColor: AppColors.tealPrimary,
      elevation: 0,
      toolbarHeight: 60,
      automaticallyImplyLeading: false,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: fgColor),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ServiceType.tautulli.brandColor,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: ServiceType.tautulli.brandColor.withAlpha(90),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              'assets/brands/tautulli.svg',
              width: 20,
              height: 20,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tautulli',
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  instance.name,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // ── Overflow menu items ───────────────────────────────────────────────────
    final moreItems = <PopupMenuEntry<String>>[
      if (hasLocalUrl)
        PopupMenuItem<String>(
          value: '__localUrl__',
          child: ListTile(
            leading: Icon(
              useLocal ? Icons.home_outlined : Icons.public,
              color: useLocal ? AppColors.tealPrimary : null,
            ),
            title: Text(useLocal ? 'Use Remote URL' : 'Use Local URL'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      if (hasLocalUrl) const PopupMenuDivider(),
      const PopupMenuItem<String>(
        value: 'graphs',
        child: ListTile(
          leading: Icon(Icons.bar_chart_outlined),
          title: Text('Graphs'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
      const PopupMenuItem<String>(
        value: 'statistics',
        child: ListTile(
          leading: Icon(Icons.leaderboard_outlined),
          title: Text('Statistics'),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    ];

    // ── BottomAppBar content ──────────────────────────────────────────────────
    final moreBtn = PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: muted),
      onSelected: (value) {
        if (value == '__localUrl__') {
          ref.read(useLocalUrlProvider(instance.id).notifier).state = !useLocal;
        } else if (value == 'graphs') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TautulliGraphsScreen(instance: instance),
            ),
          );
        } else if (value == 'statistics') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TautulliStatisticsScreen(instance: instance),
            ),
          );
        }
      },
      itemBuilder: (_) => moreItems,
    );

    late Widget bottomContent;

    if (_selectedIndex == 4) {
      // Recent tab: show media-type filter buttons
      bottomContent = Row(
        children: [
          _filterBtn('All', null, muted),
          _filterBtn('Movies', 'movie', muted),
          _filterBtn('TV', 'episode', muted),
          _filterBtn('Music', 'track', muted),
          const SizedBox(width: 4),
          // Small icon to jump back to the main section nav
          IconButton(
            icon: const Icon(Icons.grid_view_outlined),
            color: muted,
            iconSize: 20,
            tooltip: 'Sections',
            onPressed: () => setState(() => _selectedIndex = 0),
          ),
          const Spacer(),
          moreBtn,
        ],
      );
    } else {
      // Section navigation
      bottomContent = Row(
        children: [
          for (int i = 0; i < _navItems.length; i++)
            _navBtn(
              _navItems[i].$1,
              _navItems[i].$2,
              i,
              muted,
            ),
          const Spacer(),
          moreBtn,
        ],
      );
    }

    // ── Screens ───────────────────────────────────────────────────────────────
    final screens = <Widget>[
      TautulliActivityScreen(instance: instance),
      TautulliHistoryScreen(instance: instance),
      TautulliLibrariesScreen(instance: instance),
      TautulliUsersScreen(instance: instance),
      TautulliRecentlyAddedScreen(
          instance: instance, mediaTypeFilter: _recentFilter),
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: appBar,
      body: IndexedStack(index: _selectedIndex, children: screens),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.tealPrimary,
        foregroundColor: Colors.white,
        tooltip: 'Reload',
        onPressed: _reload,
        child: const Icon(Icons.refresh),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.surfaceCardDark,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: bottomContent,
      ),
    );
  }

  Widget _navBtn(IconData icon, String label, int index, Color muted) {
    final selected = _selectedIndex == index;
    final color = selected ? AppColors.tealPrimary : muted;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterBtn(String label, String? filter, Color muted) {
    final selected = _recentFilter == filter;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () => setState(() => _recentFilter = filter),
        style: TextButton.styleFrom(
          foregroundColor:
              selected ? AppColors.tealPrimary : muted,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: TextStyle(
            fontSize: 12,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.normal,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
