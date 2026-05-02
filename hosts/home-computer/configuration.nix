{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Hibernation support (swap partition labeled "swap")
  boot.kernelParams = [ "resume=/dev/disk/by-label/swap" ];
  boot.resumeDevice = "/dev/disk/by-label/swap";

  # Load WiFi driver for ASUS TUF B650-PLUS WIFI (MediaTek MT7922)
  boot.kernelModules = [ "mt7921e" ];

  # Pull MediaTek MT7922 firmware from linux-firmware
  hardware.enableRedistributableFirmware = true;

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Hostname
  networking.hostName = "home-computer";

  # Use NetworkManager for WiFi and general networking
  networking.networkmanager.enable = true;

  # Local hostname / service discovery (.local resolution)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

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
  services.xserver.xkb = {
    layout = "no";
    variant = "";
  };

  # SSH: key-only, no root login
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Allow unfree packages (Chrome, Discord, Steam, etc.)
  nixpkgs.config.allowUnfree = true;

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.settings.auto-optimise-store = true;

  system.stateVersion = "25.05";
}
