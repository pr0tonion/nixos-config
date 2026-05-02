{ config, pkgs, lib, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Plasma 6 ships bluedevil for the system tray UI, so no separate manager is needed.
}
