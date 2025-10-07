# Installation Guide

## Prerequisites

- Bootable NixOS USB drive (see [00-iso-generation.md](00-iso-generation.md))
- Ethernet cable connected to your server
- Basic familiarity with Linux command line

## Step 1: Boot from USB

1. Insert the USB drive into your server
2. Boot from the USB drive
3. Select "NixOS Installer" from the boot menu
4. Wait for the system to boot to a shell prompt

## Step 2: Network Setup

The installer should automatically get an IP via DHCP:

```bash
# Verify network connectivity
ping -c 3 nixos.org

# If no network, configure manually:
# ip addr
# dhcpcd <interface-name>
```

## Step 3: Partition the Disks

**IMPORTANT**: This will erase all data on the disk!

### For UEFI systems (recommended):

```bash
# Identify your disk
lsblk

# Partition the disk (replace /dev/sda with your disk)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# Format partitions
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2
```

### If you have a separate disk for media:

```bash
# Partition and format the media disk
parted /dev/sdb -- mklabel gpt
parted /dev/sdb -- mkpart primary 1MiB 100%
mkfs.ext4 -L media /dev/sdb1
```

## Step 4: Mount Filesystems

```bash
# Mount root
mount /dev/disk/by-label/nixos /mnt

# Create and mount boot
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Create and mount media (if separate disk)
mkdir -p /mnt/srv/media
mount /dev/disk/by-label/media /mnt/srv/media
```

## Step 5: Generate Configuration

```bash
# Generate hardware configuration
nixos-generate-config --root /mnt

# This creates:
# /mnt/etc/nixos/configuration.nix
# /mnt/etc/nixos/hardware-configuration.nix
```

## Step 6: Clone This Repository

```bash
# Install git (available in installer)
nix-shell -p git

# Clone the repository
git clone <your-repo-url> /mnt/etc/nixos-config
cd /mnt/etc/nixos-config

# Copy the generated hardware configuration
cp /mnt/etc/nixos/hardware-configuration.nix hosts/home-server/hardware-configuration.nix
```

## Step 7: Customize Configuration

Edit important settings before installation:

```bash
# Edit the hostname if desired
nano hosts/home-server/configuration.nix

# Set your timezone
# time.timeZone = "America/New_York";

# Add your SSH public key for admin user
nano modules/users.nix
# Add your SSH key to:
# openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];
```

## Step 8: Install NixOS

```bash
# Install from the flake
nixos-install --flake /mnt/etc/nixos-config#home-server

# You'll be prompted to set the root password
# Set a strong password and save it securely
```

## Step 9: Post-Installation

```bash
# Reboot into the new system
reboot

# Remove the USB drive during reboot
```

## Step 10: First Boot

After reboot:

1. The system will boot from the hard drive
2. Log in as `root` with the password you set
3. Set a password for the admin user:
   ```bash
   passwd admin
   ```
4. Add admin to sudoers if needed:
   ```bash
   usermod -aG wheel admin
   ```
5. Exit and log in as admin

## Step 11: Configure Services

SSH into your server as admin:

```bash
ssh admin@<server-ip>
```

### Set up Tailscale for remote access:

```bash
sudo tailscale up
# Follow the URL to authenticate
```

### Configure services:

1. **Plex**: Navigate to http://server-ip:32400/web
   - Claim your server with your Plex account
   - Add media libraries pointing to `/srv/media/movies` and `/srv/media/tv`

2. **Prowlarr**: http://server-ip:9696
   - Add your indexers/trackers
   - Get API key for other apps

3. **Sonarr**: http://server-ip:8989
   - Add Prowlarr as indexer source
   - Add Transmission as download client
   - Set up TV library path: `/srv/media/tv`

4. **Radarr**: http://server-ip:7878
   - Add Prowlarr as indexer source
   - Add Transmission as download client
   - Set up movie library path: `/srv/media/movies`

5. **Jellyseerr**: http://server-ip:5055
   - Connect to Plex
   - Connect to Sonarr and Radarr

6. **Transmission**: http://server-ip:9091
   - Set password on first login

7. **Grafana**: http://server-ip:3000
   - Login with admin/admin
   - Change password
   - Import dashboards (see monitoring.nix for IDs)

8. **Homepage**: http://server-ip:3001
   - Create `/etc/homepage/env` with API tokens
   - Restart: `sudo systemctl restart homepage-dashboard`

## Troubleshooting

### Installation fails

- Check disk partitioning: `lsblk`
- Verify network: `ping nixos.org`
- Check logs: `journalctl -xe`

### Can't SSH after installation

- Check if SSH is running: `systemctl status sshd`
- Verify firewall: `sudo iptables -L`
- Check network: `ip addr`

### Services won't start

- Check service status: `systemctl status <service>`
- View logs: `journalctl -u <service> -f`
- Verify permissions on `/srv/media`

## Next Steps

See [02-user-management.md](02-user-management.md) for adding additional users and configuring access.
