import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../database/app_database.dart';
import '../database/models/service_type.dart';
import '../network/dio_client.dart';
import '../theme/app_colors.dart';
import 'app_drawer.dart';

/// A shared scaffold for service detail modules (Radarr, Sonarr, etc.)
/// that provides a consistent AppBar and a nzb360-style BottomAppBar with
/// a centre-docked FAB, leading filter/sort actions, and a trailing ... menu.
class ServiceDetailShell extends ConsumerWidget {
  const ServiceDetailShell({
    super.key,
    required this.instance,
    required this.serviceName,
    this.tabs = const [],
    required this.tabViews,
    this.floatingActionButton,
    this.bottomLeadingActions,
    this.bottomTrailingActions,
    this.bottomMoreItems,
    this.onMoreSelected,
    this.tabController,
  });

  final Instance instance;
  final String serviceName;
  final List<String> tabs;
  final List<Widget> tabViews;

  /// Centre-docked FAB — shown in the BottomAppBar notch.
  final Widget? floatingActionButton;

  /// Widgets placed to the left of the FAB in the BottomAppBar (filter, sort…).
  final List<Widget>? bottomLeadingActions;

  /// Widgets placed to the right of the FAB in the BottomAppBar (view toggle…).
  final List<Widget>? bottomTrailingActions;

  /// Items for the ··· overflow menu in the BottomAppBar.
  /// The local-URL toggle is auto-prepended when [instance.localUrl] is set.
  final List<PopupMenuEntry<String>>? bottomMoreItems;

  /// Called when a value from [bottomMoreItems] is selected.
  final ValueChanged<String>? onMoreSelected;

  final TabController? tabController;

  ServiceType? get _serviceType {
    try {
      return ServiceType.values.byName(instance.serviceType);
    } catch (_) {
      return null;
    }
  }

  Color get _brandColor => _serviceType?.brandColor ?? AppColors.tealPrimary;

  static String? _iconAsset(ServiceType? type) => switch (type) {
        ServiceType.radarr   => 'assets/brands/radarr.svg',
        ServiceType.sonarr   => 'assets/brands/sonarr.svg',
        ServiceType.lidarr   => 'assets/brands/lidarr.svg',
        ServiceType.seer     => 'assets/brands/overseerr.svg',
        ServiceType.sabnzbd  => 'assets/brands/sabnzbd.svg',
        ServiceType.nzbget   => 'assets/brands/nzbget.svg',
        ServiceType.tautulli => 'assets/brands/tautulli.svg',
        ServiceType.romm     => 'assets/brands/romm.svg',
        ServiceType.rtorrent => 'assets/brands/rtorrent.svg',
        ServiceType.prowlarr => 'assets/brands/prowlarr.svg',
        _ => null,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tabs.isNotEmpty && tabViews.length != tabs.length) {
      throw ArgumentError('tabs and tabViews must have the same length');
    }

    final type       = _serviceType;
    final brandColor = _brandColor;
    final iconAsset  = _iconAsset(type);

    const fgColor      = Colors.white;
    const fgColorMuted = Color(0xA0FFFFFF);

    // ── Local URL toggle ─────────────────────────────────────────────────────
    final hasLocalUrl =
        instance.localUrl != null && instance.localUrl!.isNotEmpty;
    final useLocal = hasLocalUrl
        ? ref.watch(useLocalUrlProvider(instance.id))
        : false;

    final List<PopupMenuEntry<String>> urlItems = hasLocalUrl
        ? [
            PopupMenuItem<String>(
              value: '__localUrl__',
              child: ListTile(
                leading: Icon(
                  useLocal ? Icons.home_outlined : Icons.public,
                  color: useLocal ? brandColor : null,
                ),
                title: Text(useLocal ? 'Use Remote URL' : 'Use Local URL'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            if (bottomMoreItems?.isNotEmpty == true) const PopupMenuDivider(),
          ]
        : [];

    final allMoreItems = [...urlItems, ...?bottomMoreItems];

    final hasBottomContent = floatingActionButton != null ||
        bottomLeadingActions?.isNotEmpty == true ||
        bottomTrailingActions?.isNotEmpty == true ||
        allMoreItems.isNotEmpty;

    // ── AppBar ───────────────────────────────────────────────────────────────
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
      iconTheme: const IconThemeData(color: fgColor),
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: brandColor,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withAlpha(90),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: iconAsset != null
                ? SvgPicture.asset(
                    iconAsset,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  )
                : Text(
                    serviceName[0],
                    style: const TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  serviceName,
                  style: const TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  instance.name,
                  style: const TextStyle(
                    color: fgColorMuted,
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
      bottom: tabs.isNotEmpty
          ? TabBar(
              controller: tabController,
              indicatorColor: brandColor,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              labelColor: fgColor,
              unselectedLabelColor: fgColorMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            )
          : null,
    );

    // ── BottomAppBar ─────────────────────────────────────────────────────────
    final bottomBar = hasBottomContent
        ? BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            color: AppColors.surfaceCardDark,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Leading actions (filter, sort, etc.)
                ...?bottomLeadingActions,
                const Spacer(),
                // Trailing actions (view toggle, etc.)
                ...?bottomTrailingActions,
                // Overflow menu
                if (allMoreItems.isNotEmpty)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: fgColorMuted),
                    onSelected: (value) {
                      if (value == '__localUrl__') {
                        ref
                            .read(useLocalUrlProvider(instance.id).notifier)
                            .state = !useLocal;
                      } else {
                        onMoreSelected?.call(value);
                      }
                    },
                    itemBuilder: (_) => allMoreItems,
                  ),
              ],
            ),
          )
        : null;

    // ── Scaffold ─────────────────────────────────────────────────────────────
    final scaffold = Scaffold(
      drawer: const AppDrawer(),
      appBar: appBar,
      floatingActionButtonLocation: hasBottomContent
          ? FloatingActionButtonLocation.centerDocked
          : FloatingActionButtonLocation.endFloat,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: tabs.isNotEmpty
          ? TabBarView(
              controller: tabController,
              children: tabViews,
            )
          : (tabViews.isNotEmpty ? tabViews.first : const SizedBox.shrink()),
    );

    if (tabController == null && tabs.isNotEmpty) {
      return DefaultTabController(length: tabs.length, child: scaffold);
    }
    return scaffold;
  }
}
