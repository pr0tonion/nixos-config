{ config, pkgs, lib, ... }:

{
  # Tailscale VPN for secure remote access
  # Tailscale is easier to set up than WireGuard and works great for home servers
  services.tailscale = {
    enable = true;
    # Use the latest version
    package = pkgs.tailscale;
    # Enable IP forwarding if you want to use this as an exit node
    useRoutingFeatures = "server";
  };

  # Open Tailscale port
  networking.firewall = {
    # Allow Tailscale traffic
    trustedInterfaces = [ "tailscale0" ];

    # Allow the Tailscale UDP port through the firewall
    allowedUDPPorts = [ config.services.tailscale.port ];

    # Allow forwarding for subnet routing (optional)
    checkReversePath = "loose";
  };

  # Enable IP forwarding for subnet routing (optional)
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # ALTERNATIVE: WireGuard VPN (commented out, uncomment if you prefer WireGuard)
  # networking.wireguard.interfaces = {
  #   wg0 = {
  #     # Server mode
  #     ips = [ "10.100.0.1/24" ];
  #     listenPort = 51820;
  #
  #     # Path to private key file
  #     privateKeyFile = "/etc/wireguard/private.key";
  #
  #     # Peers (clients)
  #     peers = [
  #       # Example peer configuration
  #       # {
  #       #   publicKey = "client-public-key-here";
  #       #   allowedIPs = [ "10.100.0.2/32" ];
  #       # }
  #     ];
  #   };
  # };
  #
  # networking.firewall.allowedUDPPorts = [ 51820 ];

  # NAT configuration for WireGuard (if using WireGuard)
  # networking.nat = {
  #   enable = true;
  #   externalInterface = "eth0"; # Your main network interface
  #   internalInterfaces = [ "wg0" ];
  # };

  # NOTE: Tailscale Setup Instructions:
  # 1. After first boot, run: sudo tailscale up
  # 2. Follow the authentication URL to connect to your Tailscale account
  # 3. Access your server using its Tailscale IP or MagicDNS name
  # 4. Optional: Enable subnet routing to access other devices on your LAN
  #    Run: sudo tailscale up --advertise-routes=192.168.1.0/24
  #    (Replace with your actual LAN subnet)
  # 5. Optional: Use as exit node
  #    Run: sudo tailscale up --advertise-exit-node
  #    Then approve in Tailscale admin console

  # VPN Kill Switch for Torrent Traffic (Optional)
  # This ensures torrent traffic only goes through a commercial VPN
  # You would need to set up a separate VPN connection (e.g., Mullvad, ProtonVPN)

  # Example using OpenVPN (requires configuration file)
  # services.openvpn.servers = {
  #   torrents = {
  #     config = '' config /path/to/vpn/config.ovpn '';
  #     updateResolvConf = false;
  #   };
  # };

  # Network namespace for torrent VPN isolation (advanced)
  # This creates a separate network namespace for torrent traffic
  # systemd.services.torrent-vpn = {
  #   description = "Torrent VPN Network Namespace";
  #   after = [ "network.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #
  #   script = ''
  #     # Create network namespace
  #     ${pkgs.iproute2}/bin/ip netns add torrents
  #
  #     # Configure VPN in namespace
  #     # ... (additional configuration needed)
  #   '';
  # };
}
