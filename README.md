# NixOS Home Server Configuration

A comprehensive NixOS configuration for a home media server with automation, monitoring, and remote access.

## Features

- **Media Server**: Plex with hardware transcoding support
- **Media Automation**: Sonarr (TV), Radarr (Movies), Prowlarr (Indexers)
- **Media Requests**: Jellyseerr/Overseerr integration
- **Torrent Client**: Transmission with private tracker support
- **Remote Access**: Tailscale VPN for secure remote access
- **Monitoring**: Prometheus, Grafana, and Loki for metrics and logs
- **Dashboard**: Homepage dashboard for service overview
- **Automated Maintenance**: Media and download cleanup scripts
- **User Management**: Separate admin and service users

## Directory Structure

```
.
├── flake.nix                 # Main flake configuration
├── hosts/                    # Host-specific configurations
│   ├── home-server/         # Home server configuration
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   └── home-computer/       # Future home computer config (skeleton)
│       └── configuration.nix
├── modules/                  # Modular configuration
│   ├── base.nix             # Base system packages and settings
│   ├── networking.nix       # Network configuration and WoL
│   ├── users.nix            # User and group management
│   ├── services/            # Service configurations
│   │   ├── plex.nix
│   │   ├── media-automation.nix
│   │   ├── torrent.nix
│   │   ├── vpn.nix
│   │   ├── monitoring.nix
│   │   └── dashboard.nix
│   └── maintenance/         # Maintenance scripts
│       └── cleanup.nix
├── home/                    # Home Manager configurations
│   └── admin.nix           # Admin user configuration
└── documentation/          # User documentation
```

## Hardware Requirements

- **CPU**: Intel i7-10700 (or similar with integrated graphics)
- **RAM**: 16GB DDR4
- **Storage**: Separate partition/disk for media (/srv/media)
- **Network**: Ethernet connection recommended

## Quick Start

### 1. Installation

See [documentation/01-installation.md](documentation/01-installation.md) for detailed installation instructions.

### 2. Initial Setup

After installation:

```bash
# Clone this repository
git clone <your-repo-url> /etc/nixos
cd /etc/nixos

# Generate hardware configuration
sudo nixos-generate-config --show-hardware-config > hosts/home-server/hardware-configuration.nix

# Build and switch to the configuration
sudo nixos-rebuild switch --flake .#home-server
```

### 3. Service Configuration

All services are accessible via web interfaces:

- **Homepage Dashboard**: http://server-ip:3001
- **Plex**: http://server-ip:32400/web
- **Sonarr**: http://server-ip:8989
- **Radarr**: http://server-ip:7878
- **Prowlarr**: http://server-ip:9696
- **Jellyseerr**: http://server-ip:5055
- **Transmission**: http://server-ip:9091
- **Grafana**: http://server-ip:3000
- **Prometheus**: http://server-ip:9090

## Documentation

Detailed documentation is available in the `documentation/` directory:

1. [Adding a New User](documentation/02-user-management.md)
2. [Adding Private Trackers](documentation/03-private-trackers.md)
3. [Managing IPs and Ports](documentation/04-network-management.md)
4. [Remote Access Setup](documentation/05-remote-access.md)
5. [Deployment and Testing](documentation/06-deployment.md)
6. [What's Next](documentation/07-next-steps.md)

## Testing Before Deployment

**Don't have your physical server yet?** No problem!

You can test this entire configuration in a virtual machine before deploying to hardware. See [documentation/08-vm-testing.md](documentation/08-vm-testing.md) for a complete VM testing guide.

**Key points:**
- Works great in UTM, VirtualBox, or VMware Fusion on macOS
- All services function (except GPU transcoding and Wake-on-LAN)
- Perfect for learning NixOS and testing your configuration
- Use `#vm-test` configuration instead of `#home-server`

For other testing methods (containers, etc.), see [documentation/06-deployment.md](documentation/06-deployment.md).

## Updating

```bash
# Update flake inputs
nix flake update

# Rebuild with new configuration
sudo nixos-rebuild switch --flake .#home-server
```

## Security Notes

- All services are configured for LAN-only access
- SSH requires key-based authentication (no passwords)
- Tailscale provides secure remote access without exposing ports
- Service users run with minimal permissions
- Firewall is enabled by default

## Customization

### Changing Timezone

Edit `hosts/home-server/configuration.nix`:
```nix
time.timeZone = "America/New_York";  # Change to your timezone
```

### Adding SSH Keys

Edit `modules/users.nix` and add your SSH public key to the admin user.

### Modifying Service Ports

Service ports are defined in their respective module files under `modules/services/`.

## Troubleshooting

### Check service status
```bash
sudo systemctl status <service-name>
```

### View logs
```bash
sudo journalctl -u <service-name> -f
```

### Common services
- plex
- sonarr
- radarr
- prowlarr
- transmission
- grafana
- prometheus

## License

This configuration is provided as-is for personal use.

## Contributing

Feel free to customize this configuration for your needs. If you find improvements, consider sharing them!
