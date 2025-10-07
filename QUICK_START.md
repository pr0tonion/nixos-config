# Quick Start Guide

This is a condensed guide to get you up and running quickly. For detailed information, see the full documentation in the `documentation/` directory.

## Prerequisites

- A server with Intel i7-10700 (or similar) **OR a Virtual Machine for testing**
- USB drive for installation (8GB+) - not needed for VM
- Ethernet connection
- Basic Linux command line knowledge

> **Don't have physical hardware yet?** See [documentation/08-vm-testing.md](documentation/08-vm-testing.md) for VM testing instructions!

## Installation Steps

### 1. Create Installation Media

See [documentation/00-iso-generation.md](documentation/00-iso-generation.md) for detailed instructions.

**Quick method**: Download standard NixOS ISO from https://nixos.org/download.html

### 2. Boot and Install

1. Boot from USB
2. Partition disks:
   ```bash
   # For UEFI (recommended)
   parted /dev/sda -- mklabel gpt
   parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
   parted /dev/sda -- set 1 esp on
   parted /dev/sda -- mkpart primary 512MiB 100%

   mkfs.fat -F 32 -n boot /dev/sda1
   mkfs.ext4 -L nixos /dev/sda2
   ```

3. Mount filesystems:
   ```bash
   mount /dev/disk/by-label/nixos /mnt
   mkdir -p /mnt/boot
   mount /dev/disk/by-label/boot /mnt/boot
   ```

4. Clone this repository:
   ```bash
   nix-shell -p git
   git clone <your-repo-url> /mnt/etc/nixos-config
   cd /mnt/etc/nixos-config
   ```

5. Generate and update hardware config:
   ```bash
   nixos-generate-config --root /mnt
   cp /mnt/etc/nixos/hardware-configuration.nix hosts/home-server/hardware-configuration.nix
   ```

6. **Important**: Edit configuration:
   ```bash
   nano modules/users.nix
   # Add your SSH public key to the admin user
   ```

7. Install:
   ```bash
   nixos-install --flake /mnt/etc/nixos-config#home-server
   # Set root password when prompted
   reboot
   ```

### 3. Initial Configuration

After first boot:

```bash
# Set admin user password
passwd admin

# Set up Tailscale
sudo tailscale up

# Configure services via web interfaces:
# - Plex: http://server-ip:32400/web
# - Sonarr: http://server-ip:8989
# - Radarr: http://server-ip:7878
# - Prowlarr: http://server-ip:9696
# - Transmission: http://server-ip:9091
# - Grafana: http://server-ip:3000
# - Homepage: http://server-ip:3001
```

## Service Configuration Order

1. **Tailscale** → Enable remote access
2. **Plex** → Claim server, add libraries
3. **Prowlarr** → Add indexers/trackers
4. **Transmission** → Set password, test download
5. **Sonarr** → Add Prowlarr + Transmission
6. **Radarr** → Add Prowlarr + Transmission
7. **Jellyseerr** → Connect to Plex + Sonarr/Radarr
8. **Grafana** → Change password, import dashboards
9. **Homepage** → Add API tokens to `/etc/homepage/env`

## Essential Commands

```bash
# Rebuild system after config changes
sudo nixos-rebuild switch --flake /etc/nixos-config#home-server

# Update all packages
cd /etc/nixos-config
nix flake update
sudo nixos-rebuild switch --flake .#home-server

# Check service status
sudo systemctl status plex
sudo systemctl status sonarr
# etc.

# View logs
sudo journalctl -u plex -f

# Rollback to previous configuration
sudo nixos-rebuild switch --rollback
```

## Remote Access

### Via Tailscale (Recommended)

On your client device:
1. Install Tailscale
2. Connect to your network
3. Access services at `http://home-server:<port>`

### Via SSH

```bash
ssh admin@home-server
# Or
ssh admin@<tailscale-ip>
```

## File Locations

- **Configuration**: `/etc/nixos-config/`
- **Media**: `/srv/media/movies`, `/srv/media/tv`
- **Downloads**: `/srv/media/downloads/`
- **Service Data**: `/var/lib/<service-name>/`
- **Logs**: `journalctl -u <service-name>`

## Common Issues

### Services won't start
```bash
sudo systemctl status <service>
sudo journalctl -u <service> -n 50
```

### Can't access services remotely
1. Check Tailscale is running: `sudo tailscale status`
2. Verify service is running: `sudo systemctl status <service>`
3. Test locally: `curl http://localhost:<port>`

### Out of disk space
```bash
sudo nix-collect-garbage --delete-older-than 30d
sudo nix-store --optimize
```

### Need to rollback
```bash
sudo nixos-rebuild switch --rollback
# Or select previous generation from boot menu
```

## Next Steps

1. Read full documentation in `documentation/` directory
2. Configure private trackers (see 03-private-trackers.md)
3. Set up automated backups
4. Review security settings
5. Customize services to your needs

## Getting Help

- Full documentation: `documentation/` directory
- NixOS Manual: https://nixos.org/manual/nixos/stable/
- Community: https://discourse.nixos.org/
- Service-specific: Check each service's documentation

## Service URLs Quick Reference

| Service | URL | Default Port |
|---------|-----|--------------|
| Homepage | http://server-ip:3001 | 3001 |
| Plex | http://server-ip:32400/web | 32400 |
| Sonarr | http://server-ip:8989 | 8989 |
| Radarr | http://server-ip:7878 | 7878 |
| Prowlarr | http://server-ip:9696 | 9696 |
| Jellyseerr | http://server-ip:5055 | 5055 |
| Transmission | http://server-ip:9091 | 9091 |
| Grafana | http://server-ip:3000 | 3000 |
| Prometheus | http://server-ip:9090 | 9090 |

**Remember**: Replace `server-ip` with your server's IP address or `home-server` when using Tailscale!

## Support This Configuration

This is a complete, production-ready NixOS home server configuration. Feel free to:
- Customize for your needs
- Share improvements
- Report issues
- Contribute enhancements

Happy self-hosting! 🏠🖥️
