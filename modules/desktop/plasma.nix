{ config, pkgs, lib, ... }:

{
  services.xserver.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    settings.General.Numlock = "on";
  };

  services.desktopManager.plasma6.enable = true;
}
