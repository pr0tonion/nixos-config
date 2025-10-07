{ config, pkgs, ... }:

{
  # Define user accounts

  # Admin user - primary administrator account
  users.users.admin = {
    isNormalUser = true;
    description = "System Administrator";
    extraGroups = [
      "wheel"        # sudo access
      "networkmanager"
      "video"        # GPU access for transcoding
      "docker"       # If Docker is enabled
    ];
    # SSH keys should be added here for secure access
    openssh.authorizedKeys.keys = [
      # Add your SSH public key here:
      # "ssh-ed25519 AAAAC3... your-email@example.com"
    ];
    # Set a password or use passwordless sudo with SSH key auth
    hashedPassword = null; # Set password with: mkpasswd -m sha-512
    shell = pkgs.bash;
  };

  # Service user for media applications
  # This user runs Plex, Sonarr, Radarr, etc.
  users.users.media = {
    isSystemUser = true;
    description = "Media Services User";
    group = "media";
    extraGroups = [ "video" ]; # GPU access for Plex transcoding
  };

  # Media group
  users.groups.media = {
    gid = 1500; # Fixed GID for consistency
  };

  # Service user for torrent client
  users.users.transmission = {
    isSystemUser = true;
    description = "Transmission Torrent User";
    group = "transmission";
  };

  users.groups.transmission = {
    gid = 1501; # Fixed GID
  };

  # Service user for VPN (if needed for specific VPN setups)
  users.users.vpn = {
    isSystemUser = true;
    description = "VPN Service User";
    group = "vpn";
  };

  users.groups.vpn = {
    gid = 1502;
  };

  # Service user for monitoring
  users.users.monitoring = {
    isSystemUser = true;
    description = "Monitoring Services User";
    group = "monitoring";
  };

  users.groups.monitoring = {
    gid = 1503;
  };

  # Configure sudo
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true; # Require password for sudo
    execWheelOnly = true;
  };

  # Disable root login via SSH
  services.openssh.settings.PermitRootLogin = "no";

  # Disable password authentication (SSH key only)
  services.openssh.settings.PasswordAuthentication = false;

  # Enable SSH for admin user
  services.openssh.enable = true;

  # Create media directory with proper permissions
  systemd.tmpfiles.rules = [
    # Media directory structure
    "d /srv/media 0755 media media -"
    "d /srv/media/movies 0755 media media -"
    "d /srv/media/tv 0755 media media -"
    "d /srv/media/downloads 0755 transmission media -"
    "d /srv/media/downloads/complete 0755 transmission media -"
    "d /srv/media/downloads/incomplete 0755 transmission media -"
    "d /srv/media/downloads/watch 0755 transmission media -"

    # Temporary transcoding directory for Plex
    "d /var/lib/plex/transcode 0755 media media -"
  ];
}
