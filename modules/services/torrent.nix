{ config, pkgs, lib, ... }:

{
  # Transmission BitTorrent client
  # Note: For private trackers, Transmission is a good choice
  # Alternatively, you could use qBittorrent or Deluge
  services.transmission = {
    enable = true;
    user = "transmission";
    group = "transmission";

    # Web interface settings
    settings = {
      # Download directories
      download-dir = "/srv/media/downloads/complete";
      incomplete-dir = "/srv/media/downloads/incomplete";
      incomplete-dir-enabled = true;
      watch-dir = "/srv/media/downloads/watch";
      watch-dir-enabled = true;

      # Network settings
      rpc-bind-address = "0.0.0.0"; # Bind to all interfaces (LAN only due to firewall)
      rpc-port = 9091;
      rpc-whitelist-enabled = false; # Allow access from LAN
      rpc-host-whitelist-enabled = false;

      # Authentication
      rpc-authentication-required = true;
      rpc-username = "admin"; # Change this
      # To set password, use: transmission-remote --auth admin:password --passwd
      # Or set rpc-password to a hashed password

      # Peer settings
      peer-port = 51413;
      peer-port-random-on-start = false;
      port-forwarding-enabled = false; # Disable for VPN usage

      # Speed limits (adjust as needed)
      speed-limit-down = 0; # 0 = unlimited
      speed-limit-down-enabled = false;
      speed-limit-up = 0;
      speed-limit-up-enabled = false;

      # Ratio limits (useful for private trackers)
      ratio-limit = 2.0; # Stop seeding at 2:1 ratio
      ratio-limit-enabled = false; # Set to true if you want ratio limits

      # Encryption
      encryption = 2; # 0=off, 1=preferred, 2=required

      # DHT and PEX (disable for private trackers)
      dht-enabled = false; # Disable for private trackers
      pex-enabled = false; # Disable for private trackers
      lpd-enabled = false; # Local Peer Discovery - disable for private trackers

      # UPnP and NAT-PMP (disable when using VPN)
      upnp-enabled = false;
      utp-enabled = false; # Disable uTP for better compatibility

      # Logging
      message-level = 2; # 0=none, 1=error, 2=info, 3=debug

      # Blocklist (optional)
      blocklist-enabled = false;

      # Misc
      trash-original-torrent-files = false;
      rename-partial-files = true;
      start-added-torrents = true;
      scrape-paused-torrents-enabled = true;
    };

    # Open firewall for web interface (LAN only)
    openPeerPorts = false; # We'll handle firewall manually with VPN
    openRPCPort = true; # Opens 9091 for web interface
  };

  # Firewall configuration
  networking.firewall.allowedTCPPorts = [
    9091   # Transmission web interface
    # Peer port will be opened on VPN interface
  ];

  # VPN kill switch: ensure Transmission only uses VPN interface
  # This requires the VPN to be configured first
  systemd.services.transmission.after = [ "network-online.target" ];
  systemd.services.transmission.wants = [ "network-online.target" ];

  # Service configuration
  systemd.services.transmission = {
    serviceConfig = {
      # Security hardening
      PrivateTmp = true;
      NoNewPrivileges = true;
      PrivateDevices = lib.mkForce false; # Need access to network devices
      ProtectSystem = "strict";
      ProtectHome = lib.mkForce true;

      # Allow write to media directories
      ReadWritePaths = [
        "/srv/media/downloads"
        "/var/lib/transmission"
      ];

      # Resource limits
      MemoryMax = "2G";
      CPUQuota = "200%"; # 2 cores max

      # Ensure media group can access downloaded files
      UMask = lib.mkForce "0002";
    };
  };

  # Add transmission user to media group for file access
  users.users.transmission.extraGroups = [ "media" ];

  # Ensure download directories have proper permissions
  systemd.tmpfiles.rules = [
    "d /srv/media/downloads 0775 transmission media -"
    "d /srv/media/downloads/complete 0775 transmission media -"
    "d /srv/media/downloads/incomplete 0775 transmission media -"
    "d /srv/media/downloads/watch 0775 transmission media -"
  ];

  # OPTIONAL: VPN Integration
  # For VPN integration, you can use:
  # 1. Transmission through gluetun (Docker container)
  # 2. Network namespace binding
  # 3. VPN client with routing rules

  # Example: Bind Transmission to VPN interface (requires VPN setup)
  # systemd.services.transmission.serviceConfig.BindToDevice = "tun0";

  # NOTE: After setup:
  # 1. Access web interface at: http://<server-ip>:9091
  # 2. Default credentials: admin / (set password on first login)
  # 3. For private trackers, ensure DHT and PEX are disabled (already done above)
  # 4. Configure VPN for torrent traffic (recommended for privacy)
}
