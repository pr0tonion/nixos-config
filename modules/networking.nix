{ config, pkgs, lib, ... }:

{
  # Enable networking
  networking.networkmanager.enable = false; # Using systemd-networkd for servers
  networking.useNetworkd = true;
  systemd.network.enable = true;

  # Enable resolved for DNS
  services.resolved.enable = true;

  # Wake-on-LAN configuration
  # This enables WoL on all network interfaces
  networking.interfaces = lib.mkDefault {
    # The actual interface name will be auto-detected
    # Common names: enp0s31f6, eth0, eno1
    # This can be configured after installation with:
    # networking.interfaces.<your-interface>.wakeOnLan.enable = true;
  };

  # Firewall base configuration
  networking.firewall = {
    enable = true;
    # Default allowed ports (SSH)
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];

    # Allow local network traffic
    trustedInterfaces = [ "lo" ];

    # Log refused connections (useful for debugging)
    logRefusedConnections = true;
  };

  # Enable Wake-on-LAN support
  powerManagement.enable = true;

  # Avahi for local network service discovery (optional but useful)
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      domain = true;
      hinfo = true;
      userServices = true;
      workstation = true;
    };
  };
}
