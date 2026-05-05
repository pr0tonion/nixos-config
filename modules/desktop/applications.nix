{ config, pkgs, pkgs-unstable, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core / requested
    git
    lazygit
    neovim
    google-chrome
    discord
    ghostty
    android-studio
    python313
    nodejs
    vscode-fhs

    # Plasma tiling window manager (enable in System Settings -> KWin Scripts)
    kdePackages.krohnkite

    # General desktop
    firefox
    mpv
    obs-studio
    bitwarden-desktop
    signal-desktop
    libreoffice-fresh
    gimp
    spotify
    thunderbird

    # AI tooling — pulled from unstable for the latest version
    pkgs-unstable.claude-code

    # Gaming overlay — shows FPS, frametimes, GPU/CPU load in-game
    mangohud

    # Gaming platform for non-Steam games (Wine, emulators, etc.)
    lutris

    # WoW addon manager with CurseForge support
    pkgs-unstable.wowup-cf

    # Docker CLI and Compose plugin
    docker-compose
  ];

  # Steam (Proton is downloaded through Steam itself, no separate package needed)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
    # Proton-GE: better game compatibility and performance than stock Proton for many titles
    extraCompatPackages = [ pkgs.proton-ge-bin ];
  };

  hardware.steam-hardware.enable = true;

  # CPU governor + niceness boost for games that opt in
  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  # Docker daemon — admin is added to the docker group in modules/desktop/users.nix
  virtualisation.docker.enable = true;

  # Android Studio USB debugging (admin is added to the adbusers group in modules/desktop/users.nix)
  programs.adb.enable = true;

  # Allow Mason (Neovim) and other prebuilt generic-Linux binaries to run on NixOS.
  # Without this, dynamically linked executables fail with "Could not start ...".
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib   # libstdc++ — required by lua-language-server and most native LSPs
      zlib
      openssl
      icu
      libgcc
    ];
  };
}
