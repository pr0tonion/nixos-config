{ config, pkgs, lib, ... }:

{
  # This is a skeleton configuration for a home computer
  # To be expanded when needed

  # Bootloader configuration
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hostname
  networking.hostName = "home-computer";

  # Timezone and locale
  time.timeZone = "UTC"; # Change to your timezone
  i18n.defaultLocale = "en_US.UTF-8";

  # System state version
  system.stateVersion = "24.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable periodic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
  ];

  # TODO: Add desktop environment, user configurations, etc.
}
