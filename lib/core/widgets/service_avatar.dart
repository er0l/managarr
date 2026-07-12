import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../database/models/service_type.dart';
import '../theme/app_colors.dart';

/// Rounded square tile with the service's brand color and SVG logo.
/// Shared by the dashboard status strip, drawer, and settings tiles.
class ServiceAvatar extends StatelessWidget {
  const ServiceAvatar({super.key, required this.type, this.size = 40});

  final ServiceType type;
  final double size;

  static String assetForType(ServiceType type) => switch (type) {
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
      };

  @override
  Widget build(BuildContext context) {
    final bg = type.brandColor;
    final fg =
        type.brandColorNeedsDarkText ? AppColors.textPrimary : Colors.white;
    final radius = size * 0.25;
    final iconSize = size * 0.60;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        assetForType(type),
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
      ),
    );
  }
}
