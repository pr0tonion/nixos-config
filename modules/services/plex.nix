{ config, pkgs, lib, ... }:

{
  # Plex Media Server configuration
  services.plex = {
    enable = true;
    openFirewall = true; # Opens port 32400 automatically
    user = "media";
    group = "media";
    dataDir = "/var/lib/plex";
  };

  # Ensure Plex has access to media directories
  systemd.services.plex.serviceConfig = {
    # Allow access to hardware acceleration
    SupplementaryGroups = [ "video" "render" ];

    # Bind media directories
    BindPaths = [
      "/srv/media/movies"
      "/srv/media/tv"
    ];

    # Resource limits
    MemoryMax = "8G"; # Adjust based on your needs
    CPUQuota = "400%"; # Allow up to 4 CPU cores
  };

  # Enable hardware transcoding support for Intel GPU
  # This requires the Intel GPU drivers to be properly configured
  # (already done in hardware-configuration.nix)

  # Additional firewall rules for Plex
  networking.firewall = {
    allowedTCPPorts = [
      32400  # Plex Media Server
      3005   # Plex Companion
      8324   # Roku via Plex Companion
    ];
    allowedUDPPorts = [
      1900   # Plex DLNA Server
      5353   # Bonjour/Avahi
      32410  # Plex GDM Network Discovery
      32412  # Plex GDM Network Discovery
      32413  # Plex GDM Network Discovery
      32414  # Plex GDM Network Discovery
    ];
  };

  # Environment variables for Plex
  systemd.services.plex.environment = {
    # Enable hardware transcoding
    PLEX_MEDIA_SERVER_USE_SYSLOG = "true";
  };

  # Ensure the transcode directory exists and is writable
  systemd.tmpfiles.rules = [
    "d /var/lib/plex/transcode 0755 media media -"
    "d /var/lib/plex/Library 0755 media media -"
  ];

  # NOTE: After first setup, you'll need to claim your Plex server
  # Access Plex at: http://<server-ip>:32400/web
  # Hardware transcoding requires Plex Pass subscription
}
