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

  # Plex and the *arr apps watch large libraries with inotify. Kept here, not in
  # hardware-configuration.nix, so it survives regenerating that file.
  boot.kernel.sysctl."fs.inotify.max_user_watches" = 524288;

  # Allow unfree packages (needed for Plex, etc.)
  nixpkgs.config.allowUnfree = true;

  # Pull and switch to main nightly. flake.lock on main is bumped weekly by the
  # update-flake-lock workflow (.github/workflows/update-flake-lock.yml), so this
  # tracks the latest nixos-26.05 security fixes without touching inputs itself.
  # No automatic reboots: kernel updates take effect on the next manual reboot.
  system.autoUpgrade = {
    enable = true;
    flake = "github:pr0tonion/nixos-config#home-server";
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };

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
