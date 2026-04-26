import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../database/app_database.dart';
import '../database/models/service_type.dart';
import '../theme/app_colors.dart';
import 'app_drawer.dart';

/// A shared scaffold for service detail modules (Radarr, Sonarr, etc.)
/// that provides a consistent AppBar with the app's teal background,
/// a brand-colour icon avatar, the service name, and the instance name.
///
/// All service home screens use this widget so the chrome matches the rest
/// of the app shell (Dashboard, Search, Settings).
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

    final type      = _serviceType;
    final brandColor = _brandColor;
    final iconAsset  = _iconAsset(type);

    // All service AppBars use the app teal — white text is always legible.
    const fgColor      = Colors.white;
    const fgColorMuted = Color(0xA0FFFFFF); // white @ ~63 % opacity

    final scaffold = Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
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
            // Brand-colour icon avatar — gives each service its own identity
            // while keeping the overall chrome consistent.
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

    // If tabs are present but no external controller, wrap in DefaultTabController.
    if (tabController == null && tabs.isNotEmpty) {
      return DefaultTabController(
        length: tabs.length,
        child: scaffold,
      );
    }

    return scaffold;
  }
}
