{ config, pkgs, lib, ... }:

{
  # Admin user for the home-computer (desktop) host.
  # Distinct from the home-server admin in modules/users.nix:
  # different machine, different group set (audio/input/adbusers for desktop use).
  users.users.admin = {
    isNormalUser = true;
    description = "Marcus";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "input"
      "adbusers"
      "docker"
    ];
    # Set on first boot. Change immediately with `passwd` after logging in.
    initialPassword = "admin";
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # Add SSH public key here once one is generated on the desktop.
    ];
  };

  security.sudo.wheelNeedsPassword = true;
}
