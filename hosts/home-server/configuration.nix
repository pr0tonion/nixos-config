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
  time.timeZone = "Europe/Oslo";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "nb_NO.UTF-8";
      LC_MONETARY = "nb_NO.UTF-8";
      LC_MEASUREMENT = "nb_NO.UTF-8";
      LC_PAPER = "nb_NO.UTF-8";
    };
  };

  # Norwegian keyboard layout
  console.keyMap = "no";

  # X11 keyboard layout (for GUI if needed)
  services.xserver.xkb = {
    layout = "no";
    variant = "";
  };

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
