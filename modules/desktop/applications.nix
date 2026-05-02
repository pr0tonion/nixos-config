{ config, pkgs, pkgs-unstable, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core / requested
    git
    lazygit
    neovim
    google-chrome
    discord
    alacritty
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
  ];

  # Steam (Proton is downloaded through Steam itself, no separate package needed)
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };

  hardware.steam-hardware.enable = true;

  # CPU governor + niceness boost for games that opt in (Lutris, Heroic, many native titles)
  programs.gamemode.enable = true;

  # Android Studio USB debugging (admin is added to the adbusers group in modules/desktop/users.nix)
  programs.adb.enable = true;
}
