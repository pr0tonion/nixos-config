{ config, pkgs, lib, ... }:

{
  # VM Test Configuration
  # This is optimized for testing in a virtual machine

  # Import the base home-server configuration
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
  networking.hostName = "home-server-vm";

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

  # System state version
  system.stateVersion = "24.05";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Optimize store
  nix.settings.auto-optimise-store = true;

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true; # Enable for VM testing
      PermitRootLogin = "no";
    };
  };

  # Firewall
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # VM-specific: Disable hardware transcoding in Plex
  # (GPU passthrough is complex in VMs)
  services.plex = {
    enable = true;
    openFirewall = true;
    user = "media";
    group = "media";
  };

  # Reduce resource usage for VM
  systemd.services.plex.serviceConfig.MemoryMax = lib.mkForce "2G";
  systemd.services.prometheus.serviceConfig.MemoryMax = lib.mkForce "512M";
  systemd.services.grafana.serviceConfig.MemoryMax = lib.mkForce "512M";

  # For VM testing, you might want to use smaller media files
  # or mount a shared folder from host

  # Enable guest additions for better VM integration
  virtualisation.vmware.guest.enable = lib.mkDefault false;
  virtualisation.virtualbox.guest.enable = lib.mkDefault false;

  # QEMU guest agent (if using QEMU/KVM)
  services.qemuGuest.enable = lib.mkDefault true;
}
