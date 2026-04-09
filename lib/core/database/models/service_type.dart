enum ServiceType {
  radarr,
  sonarr,
  lidarr,
  prowlarr,
  seer,
  sabnzbd,
  rtorrent,
  nzbget,
  tautulli,
  romm;

  String get displayName => switch (this) {
        ServiceType.radarr => 'Radarr',
        ServiceType.sonarr => 'Sonarr',
        ServiceType.lidarr => 'Lidarr',
        ServiceType.prowlarr => 'Prowlarr',
        ServiceType.seer => 'Seer',
        ServiceType.sabnzbd => 'SABnzbd',
        ServiceType.rtorrent => 'rTorrent',
        ServiceType.nzbget => 'NZBGet',
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
        // SABnzbd uses query-param auth; path is handled separately.
        ServiceType.sabnzbd => '/api',
        // rTorrent uses XML-RPC; health check handled separately.
        ServiceType.rtorrent => '/RPC2',
        // NZBGet uses JSON-RPC; health check handled separately.
        ServiceType.nzbget => '/jsonrpc',
        ServiceType.tautulli => '/api/v2?cmd=server_status',
        ServiceType.romm => '/api/platforms',
      };

  bool get usesBasicAuth =>
      this == ServiceType.rtorrent ||
      this == ServiceType.nzbget ||
      this == ServiceType.romm;

  bool get usesSabnzbdAuth => this == ServiceType.sabnzbd;
  bool get usesXmlRpc => this == ServiceType.rtorrent;
}
