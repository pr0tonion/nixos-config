{ config, pkgs, ... }:

{
  # Essential system packages
  environment.systemPackages = with pkgs; [
    # System tools
    git
    vim
    neovim
    wget
    curl
    htop
    btop
    tree
    unzip
    zip
    rsync

    # Network tools
    dnsutils
    nettools
    inetutils
    nmap

    # Disk utilities
    smartmontools
    ncdu

    # System monitoring
    lm_sensors
    pciutils
    usbutils
  ];

  # Enable smartd for disk monitoring
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.mail.enable = false; # Can be enabled with email setup
  };

  # Systemd journal configuration
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=7day
  '';

  # Enable periodic TRIM for SSDs
  services.fstrim.enable = true;

  # Automatic updates for security patches (optional - can be disabled if preferred)
  system.autoUpgrade = {
    enable = false; # Set to true if you want automatic updates
    allowReboot = false;
    dates = "weekly";
  };
}
