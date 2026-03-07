{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    git
    lazygit
    neovim
    google-chrome
    discord
    alacritty
    android-studio
    python313
    nodejs
    vscode
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
  };

  hardware.steam-hardware.enable = true;
}
