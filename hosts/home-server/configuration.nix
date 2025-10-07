{ config, pkgs, lib, ... }:

{
  # Import hardware configuration
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hostname
  networking.hostName = "home-server";

  # Timezone and locale
  time.timeZone = "UTC"; # Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # System state version (don't change after installation)
  system.stateVersion = "24.05";

  # Allow unfree packages (needed for Plex, etc.)
  nixpkgs.config.allowUnfree = true;

  # Enable periodic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimize nix store
  nix.settings.auto-optimise-store = true;

  # Enable SSH for remote management
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Firewall configuration - only allow necessary ports on LAN
  networking.firewall = {
    enable = true;
    # Allow SSH, Plex, and service ports
    allowedTCPPorts = [ 22 ];
    # Additional ports will be opened by service modules
  };
}
