import 'package:flutter/material.dart';

enum ServiceType {
  radarr,
  sonarr,
  lidarr,
  prowlarr,
  seer,
  rtorrent,
  tautulli,
  romm;

  /// Official brand colors sourced from simpleicons.org / each service's
  /// visual identity. Matches the Kit.jsx SERVICES map in the design system.
  Color get brandColor => switch (this) {
        ServiceType.radarr   => const Color(0xFFFFC230), // golden yellow
        ServiceType.sonarr   => const Color(0xFF2596BE), // teal-blue
        ServiceType.lidarr   => const Color(0xFF00AF43), // green
        ServiceType.prowlarr => const Color(0xFFE66000), // burnt orange
        ServiceType.seer     => const Color(0xFF6366F1), // indigo
        ServiceType.rtorrent => const Color(0xFF2C7A3E), // dark green
        ServiceType.tautulli => const Color(0xFFE39419), // amber
        ServiceType.romm     => const Color(0xFF7C3AED), // purple
      };

  /// Returns true when the brand color is light enough to need dark text/icon.
  bool get brandColorNeedsDarkText => this == ServiceType.radarr;

  String get displayName => switch (this) {
        ServiceType.radarr => 'Radarr',
        ServiceType.sonarr => 'Sonarr',
        ServiceType.lidarr => 'Lidarr',
        ServiceType.prowlarr => 'Prowlarr',
        ServiceType.seer => 'Seer',
        ServiceType.rtorrent => 'rTorrent',
        ServiceType.tautulli => 'Tautulli',
        ServiceType.romm => 'ROMM',
      };

  /// API path used to verify connectivity.
  String get healthPath => switch (this) {
        ServiceType.radarr => '/api/v3/system/status',
        ServiceType.sonarr => '/api/v3/system/status',
        ServiceType.lidarr => '/api/v1/system/status',
        ServiceType.prowlarr => '/api/v1/system/status',
        ServiceType.seer => '/api/v1/settings/main',
        // rTorrent uses XML-RPC; health check handled separately.
        ServiceType.rtorrent => '/RPC2',
        ServiceType.tautulli => '/api/v2?cmd=server_status',
        ServiceType.romm => '/api/platforms',
      };

  bool get usesBasicAuth =>
      this == ServiceType.rtorrent || this == ServiceType.romm;

  bool get usesXmlRpc => this == ServiceType.rtorrent;
}
