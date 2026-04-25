import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../database/app_database.dart';
import '../database/models/service_type.dart';
import '../theme/app_colors.dart';
import 'app_drawer.dart';

/// A shared scaffold for service detail modules (Radarr, Sonarr, etc.)
/// that provides a consistent AppBar with a brand-gradient background,
/// service icon, instance name, and optional tabs.
///
/// The AppBar gradient is derived automatically from the instance's service
/// type — no extra parameters needed for callers.
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
  Widget build(BuildContext context) {
    if (tabs.isNotEmpty && tabViews.length != tabs.length) {
      throw ArgumentError('tabs and tabViews must have the same length');
    }

    final type = _serviceType;
    final brandColor = _brandColor;
    final iconAsset = _iconAsset(type);
    final needsDarkFg = type?.brandColorNeedsDarkText ?? false;
    final fgColor = needsDarkFg ? AppColors.textPrimary : Colors.white;
    final fgColorMuted = needsDarkFg
        ? AppColors.textPrimary.withAlpha(160)
        : Colors.white.withAlpha(160);

    final scaffold = Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        // Brand-color → tealDark gradient fills the AppBar background.
        flexibleSpace: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.alphaBlend(brandColor.withAlpha(200), AppColors.tealDark),
                AppColors.tealDark,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Icon(Icons.menu, color: fgColor),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        iconTheme: IconThemeData(color: fgColor),
        title: Row(
          children: [
            // Brand icon avatar with subtle glow.
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
                      colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
                    )
                  : Text(
                      serviceName[0],
                      style: TextStyle(
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
                    style: TextStyle(
                      color: fgColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    instance.name,
                    style: TextStyle(
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
        actions: actions,
        bottom: tabs.isNotEmpty
            ? TabBar(
                controller: tabController,
                indicatorColor: AppColors.orangeAccent,
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
      ),
      body: tabs.isNotEmpty
          ? TabBarView(
              controller: tabController,
              children: tabViews,
            )
          : (tabViews.isNotEmpty ? tabViews.first : const SizedBox.shrink()),
      floatingActionButton: floatingActionButton,
    );

    // If tabs are present but no controller is provided, wrap in DefaultTabController.
    if (tabController == null && tabs.isNotEmpty) {
      return DefaultTabController(
        length: tabs.length,
        child: scaffold,
      );
    }

    return scaffold;
  }
}
