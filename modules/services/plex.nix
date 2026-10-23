{ pkgs, ... }:

{
  # Plex Media Server configuration
  services.plex = {
    enable = true;
    # Opens TCP 32400/3005/8324/32469 and UDP 1900/5353/32410-32414 (GDM discovery, DLNA)
    openFirewall = true;
    user = "media";
    group = "media";
    dataDir = "/var/lib/plex";
  };

  # Intel Quick Sync for hardware transcoding (requires Plex Pass). Lives here rather
  # than in hardware-configuration.nix, which is regenerated on each new machine.
  # Swap these packages if the replacement server has a different GPU.
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver # VAAPI (iHD) for Broadwell and newer
      intel-compute-runtime # OpenCL, used by Plex HDR tone mapping
    ];
  };

  # Ensure Plex has access to media directories
  systemd.services.plex.serviceConfig = {
    # Allow access to hardware acceleration
    SupplementaryGroups = [
      "video"
      "render"
    ];

    # Bind media directories
    BindPaths = [
      "/srv/media/movies"
      "/srv/media/tv"
    ];

    # Resource limits
    MemoryMax = "8G"; # Adjust based on your needs
    CPUQuota = "400%"; # Allow up to 4 CPU cores
  };

  # Send Plex logs to syslog/journald, so Alloy ships them to Loki
  systemd.services.plex.environment.PLEX_MEDIA_SERVER_USE_SYSLOG = "true";

  # Ensure the transcode directory exists and is writable
  systemd.tmpfiles.rules = [
    "d /var/lib/plex/transcode 0755 media media -"
    "d /var/lib/plex/Library 0755 media media -"
  ];

  # NOTE: After first setup, you'll need to claim your Plex server
  # Access Plex at: http://<server-ip>:32400/web
  # Hardware transcoding requires Plex Pass subscription
}
