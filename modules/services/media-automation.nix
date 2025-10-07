{ config, pkgs, lib, ... }:

{
  # Sonarr - TV Show automation
  services.sonarr = {
    enable = true;
    user = "media";
    group = "media";
    openFirewall = true; # Opens port 8989
  };

  # Radarr - Movie automation
  services.radarr = {
    enable = true;
    user = "media";
    group = "media";
    openFirewall = true; # Opens port 7878
  };

  # Prowlarr - Indexer manager
  services.prowlarr = {
    enable = true;
    openFirewall = true; # Opens port 9696
  };

  # Overseerr/Jellyseerr - Media request management
  # Note: Overseerr is not in nixpkgs by default, using Jellyseerr as alternative
  # or we can package Overseerr manually
  services.jellyseerr = {
    enable = true;
    openFirewall = true; # Opens port 5055
  };

  # Additional firewall rules
  networking.firewall.allowedTCPPorts = [
    8989   # Sonarr
    7878   # Radarr
    9696   # Prowlarr
    5055   # Jellyseerr (Overseerr alternative)
  ];

  # Configure service directories and permissions
  systemd.tmpfiles.rules = [
    # Sonarr
    "d /var/lib/sonarr 0755 media media -"

    # Radarr
    "d /var/lib/radarr 0755 media media -"

    # Prowlarr
    "d /var/lib/prowlarr 0755 media media -"

    # Jellyseerr
    "d /var/lib/jellyseerr 0755 media media -"
  ];

  # Service configurations
  systemd.services.sonarr = {
    serviceConfig = {
      # Bind media directories
      BindPaths = [
        "/srv/media/tv"
        "/srv/media/downloads"
      ];
      # Resource limits
      MemoryMax = "1G";
    };
  };

  systemd.services.radarr = {
    serviceConfig = {
      # Bind media directories
      BindPaths = [
        "/srv/media/movies"
        "/srv/media/downloads"
      ];
      # Resource limits
      MemoryMax = "1G";
    };
  };

  systemd.services.prowlarr = {
    serviceConfig = {
      # Resource limits
      MemoryMax = "512M";
    };
  };

  systemd.services.jellyseerr = {
    serviceConfig = {
      # Resource limits
      MemoryMax = "512M";
    };
  };

  # NOTE: Configuration steps after installation:
  # 1. Sonarr: http://<server-ip>:8989
  # 2. Radarr: http://<server-ip>:7878
  # 3. Prowlarr: http://<server-ip>:9696
  # 4. Jellyseerr: http://<server-ip>:5055
  #
  # Setup order:
  # 1. Configure Prowlarr with your indexers/trackers
  # 2. Connect Sonarr and Radarr to Prowlarr
  # 3. Configure download client (Transmission) in Sonarr/Radarr
  # 4. Set up media libraries pointing to /srv/media/tv and /srv/media/movies
  # 5. Configure Jellyseerr to connect to Plex and Sonarr/Radarr
}
