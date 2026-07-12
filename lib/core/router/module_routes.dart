import '../database/models/service_type.dart';

/// Full-screen module route for a service instance.
String moduleRouteFor(ServiceType type, int instanceId) => switch (type) {
      ServiceType.radarr   => '/radarr/$instanceId',
      ServiceType.sonarr   => '/sonarr/$instanceId',
      ServiceType.lidarr   => '/lidarr/$instanceId',
      ServiceType.seer     => '/seer/$instanceId',
      ServiceType.rtorrent => '/rtorrent/$instanceId',
      ServiceType.sabnzbd  => '/sabnzbd/$instanceId',
      ServiceType.prowlarr => '/prowlarr/$instanceId',
      ServiceType.nzbget   => '/nzbget/$instanceId',
      ServiceType.tautulli => '/tautulli/$instanceId',
      ServiceType.romm     => '/romm/$instanceId',
    };
