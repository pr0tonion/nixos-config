# Network Management - IPs and Ports

This guide explains how to manage network settings, including IP addresses, ports, and firewall rules.

## Service Ports Overview

### Currently Configured Ports

| Service | Port | Protocol | Access |
|---------|------|----------|--------|
| SSH | 22 | TCP | LAN |
| Plex | 32400 | TCP | LAN |
| Plex Companion | 3005 | TCP | LAN |
| Plex Roku | 8324 | TCP | LAN |
| Plex DLNA | 1900 | UDP | LAN |
| Plex GDM | 32410-32414 | UDP | LAN |
| Sonarr | 8989 | TCP | LAN |
| Radarr | 7878 | TCP | LAN |
| Prowlarr | 9696 | TCP | LAN |
| Jellyseerr | 5055 | TCP | LAN |
| Transmission Web | 9091 | TCP | LAN |
| Transmission Peer | 51413 | TCP/UDP | External* |
| Grafana | 3000 | TCP | LAN |
| Prometheus | 9090 | TCP | LAN |
| Loki | 3100 | TCP | LAN |
| Homepage | 3001 | TCP | LAN |
| Tailscale | Dynamic | UDP | External |

*External ports are only opened for VPN services

## Changing Service Ports

### Method 1: Edit Service Module

Each service has its configuration in `modules/services/`. To change a port:

#### Example: Changing Plex Port

Edit `modules/services/plex.nix`:

```nix
# This requires adding custom configuration
services.plex = {
  enable = true;
  # ... other settings ...
};

# Most services don't expose port configuration directly
# You may need to override the service configuration
```

**Note**: Many NixOS service modules don't expose port configuration. See Method 2 for alternatives.

#### Example: Changing Transmission Port

Edit `modules/services/torrent.nix`:

```nix
services.transmission = {
  settings = {
    rpc-port = 9091;  # Change to your desired port
    peer-port = 51413;  # Change peer port
  };
};
```

#### Example: Changing Grafana Port

Edit `modules/services/monitoring.nix`:

```nix
services.grafana = {
  settings = {
    server = {
      http_port = 3000;  # Change to your desired port
    };
  };
};
```

### Method 2: Using Systemd Overrides

For services that don't expose port configuration:

```nix
# In the appropriate module file
systemd.services.<service-name>.environment = {
  PORT = "8080";
};
```

### Method 3: Reverse Proxy (Recommended)

Instead of changing ports, use Nginx as a reverse proxy:

Create `modules/services/nginx.nix`:

```nix
{ config, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;

    virtualHosts = {
      "plex.home-server.local" = {
        locations."/" = {
          proxyPass = "http://localhost:32400";
          proxyWebsockets = true;
        };
      };

      "sonarr.home-server.local" = {
        locations."/" = {
          proxyPass = "http://localhost:8989";
        };
      };

      # Add more services as needed
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

Then add to `flake.nix`:
```nix
./modules/services/nginx.nix
```

### After Changing Ports

1. Update firewall rules (see below)
2. Rebuild the system:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos-config#home-server
   ```
3. Update bookmarks/homepage configuration
4. Update inter-service connections (Sonarr → Radarr, etc.)

## Managing Firewall Rules

### Viewing Current Firewall Rules

```bash
# View firewall rules
sudo iptables -L -n -v

# View NixOS firewall configuration
sudo systemctl status firewall
```

### Opening Additional Ports

Edit the relevant module or create a custom firewall rule.

#### Example: Open Port 8080

In `modules/networking.nix`:

```nix
networking.firewall = {
  allowedTCPPorts = [ 22 8080 ];  # Add your port
  allowedUDPPorts = [ ];
};
```

Or in a specific service module:

```nix
# In modules/services/your-service.nix
networking.firewall.allowedTCPPorts = [ 8080 ];
```

### Closing Ports

Remove the port from the `allowedTCPPorts` or `allowedUDPPorts` list and rebuild.

### Port Ranges

```nix
networking.firewall = {
  allowedTCPPortRanges = [
    { from = 8000; to = 8100; }
  ];
};
```

## IP Address Configuration

### Static IP (Recommended for Servers)

Create `modules/networking-static.nix`:

```nix
{ config, lib, ... }:

{
  # Disable DHCP
  networking.useDHCP = false;

  # Configure static IP
  networking.interfaces.enp0s31f6 = {  # Replace with your interface name
    useDHCP = false;
    ipv4.addresses = [{
      address = "192.168.1.100";  # Your desired IP
      prefixLength = 24;  # Usually 24 for /24 networks
    }];
  };

  # Default gateway
  networking.defaultGateway = "192.168.1.1";

  # DNS servers
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
}
```

Add to `flake.nix`:
```nix
./modules/networking-static.nix
```

### Find Your Network Interface

```bash
ip addr show
# Look for your ethernet interface (usually starts with 'e')
```

### DHCP (Default)

The current configuration uses systemd-networkd with DHCP. This is configured in `modules/networking.nix`.

### DHCP Reservation (Alternative to Static IP)

Instead of static IP on the server, configure your router to always assign the same IP to your server's MAC address. This is often the preferred method.

1. Find your server's MAC address:
   ```bash
   ip link show
   ```
2. In your router settings, create a DHCP reservation
3. Map the MAC address to your desired IP

## DNS Configuration

### Local DNS Names

Edit `/etc/hosts` on your client machines:

```
192.168.1.100  home-server
192.168.1.100  plex.local
192.168.1.100  grafana.local
```

Or use Avahi (already configured):
- Server will be accessible as `home-server.local`

### Custom DNS Server

To use custom DNS servers, edit `modules/networking.nix`:

```nix
networking.nameservers = [
  "1.1.1.1"      # Cloudflare
  "8.8.8.8"      # Google
  "192.168.1.1"  # Your router
];
```

## Wake-on-LAN Configuration

### Enable WoL on Network Interface

Edit `modules/networking.nix`:

```nix
networking.interfaces.enp0s31f6.wakeOnLan.enable = true;
```

Replace `enp0s31f6` with your actual interface name.

### Send WoL Packet

From another machine on your network:

```bash
# Install wakeonlan
# NixOS: nix-shell -p wakeonlan
# Ubuntu: apt install wakeonlan
# macOS: brew install wakeonlan

# Send magic packet (replace with your server's MAC)
wakeonlan AA:BB:CC:DD:EE:FF
```

### Find MAC Address

On the server:
```bash
ip link show | grep ether
```

## VPN Network Configuration

### Tailscale IP Range

Tailscale automatically assigns IPs in the 100.x.x.x range. You can find your server's Tailscale IP:

```bash
tailscale ip -4
```

### Accessing Services via Tailscale

Once connected to Tailscale, access services using the Tailscale IP:

```
http://<tailscale-ip>:32400/web  # Plex
http://<tailscale-ip>:3001       # Homepage
```

Or use MagicDNS (enabled by default):

```
http://home-server:32400/web
```

### Subnet Routing via Tailscale

To access other devices on your home network through Tailscale:

```bash
# On the server
sudo tailscale up --advertise-routes=192.168.1.0/24

# Approve the routes in the Tailscale admin console
```

Then from anywhere, you can access any device on your home network via the Tailscale connection.

## Port Forwarding on Router

**Generally NOT recommended** - use Tailscale instead for remote access.

If you must forward ports:

1. Access your router admin panel
2. Find "Port Forwarding" or "Virtual Server" settings
3. Forward external ports to internal IP:port
   - Example: External 32400 → 192.168.1.100:32400
4. **Only forward if absolutely necessary and you understand the security implications**

## Monitoring Network Traffic

### Real-time Traffic

```bash
# Install if not available
nix-shell -p iftop

# Monitor traffic
sudo iftop -i enp0s31f6  # Replace with your interface
```

### Traffic Statistics

```bash
# Bandwidth usage
ip -s link

# Connection statistics
ss -s

# Active connections
ss -tunap
```

### Using Prometheus/Grafana

Network metrics are automatically collected by the node_exporter. View them in Grafana:

1. Access Grafana: `http://server-ip:3000`
2. Import Dashboard ID: 1860 (Node Exporter Full)
3. View network metrics in the dashboard

## Security Best Practices

1. **Never expose services directly to the internet** without proper authentication
2. **Use Tailscale** for remote access instead of port forwarding
3. **Keep firewall enabled** at all times
4. **Use strong passwords** for all web interfaces
5. **Regularly update** the system: `sudo nixos-rebuild switch --flake /etc/nixos-config#home-server`
6. **Monitor logs** for suspicious activity: `sudo journalctl -f`
7. **Use HTTPS** when possible (consider adding nginx with SSL)
8. **Limit SSH** to key-based authentication only (already configured)

## Troubleshooting

### Can't access service from another computer

1. Check if service is running:
   ```bash
   sudo systemctl status <service>
   ```

2. Check if port is listening:
   ```bash
   sudo ss -tlnp | grep <port>
   ```

3. Check firewall:
   ```bash
   sudo iptables -L -n | grep <port>
   ```

4. Test from server:
   ```bash
   curl http://localhost:<port>
   ```

5. Check network connectivity:
   ```bash
   ping <server-ip>
   ```

### Firewall blocking legitimate traffic

Temporarily disable to test:
```bash
sudo systemctl stop firewall
# Test your connection
sudo systemctl start firewall
```

If that fixes it, add the port to the firewall configuration.

### Service won't start after changing port

1. Check if new port is in use:
   ```bash
   sudo ss -tlnp | grep <new-port>
   ```

2. Check service logs:
   ```bash
   sudo journalctl -u <service> -n 50
   ```

3. Verify firewall allows the new port

### Network interface name changed

After hardware changes, interface names may change:

1. Find new name:
   ```bash
   ip link show
   ```

2. Update in configuration files
3. Rebuild: `sudo nixos-rebuild switch`
