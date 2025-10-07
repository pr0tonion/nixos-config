# VM Testing - Ultra Quick Start

**TL;DR**: Test your entire home server setup in a VM on your Mac before buying hardware!

## Fastest Path to Testing

### 1. Download Software (5 minutes)

**VM Software** (pick one):
- **UTM** (recommended for M1/M2): https://mac.getutm.app/
- **VirtualBox** (Intel Macs): `brew install --cask virtualbox`

**NixOS ISO**:
- https://nixos.org/download → "Minimal ISO image" (~900MB)

### 2. Create VM (5 minutes)

**UTM**:
- New VM → Virtualize → Linux
- Boot ISO: Select NixOS ISO
- RAM: 8GB, CPU: 4 cores, Disk: 60GB
- Start VM

**VirtualBox**:
- New → Linux/Other Linux 64-bit
- RAM: 8GB, Disk: 60GB VDI
- Settings → Storage → Add NixOS ISO
- Settings → Network → Bridged
- Start VM

### 3. Install (30 minutes)

In the VM terminal:

```bash
# Partition disk
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Get config (if you've pushed to GitHub)
nix-shell -p git
git clone YOUR_REPO_URL /mnt/etc/nixos-config
cd /mnt/etc/nixos-config

# Generate hardware config
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/vm-test/hardware-configuration.nix

# Install
nixos-install --flake /mnt/etc/nixos-config#vm-test
# Set root password when prompted

# Reboot
reboot
```

Remove ISO before rebooting!

### 4. Access Services (5 minutes)

Find VM IP:
```bash
ip addr show
# Look for 192.168.x.x
```

From your Mac browser:
```
http://VM_IP:3001   → Homepage (start here!)
http://VM_IP:32400/web → Plex
http://VM_IP:8989   → Sonarr
http://VM_IP:7878   → Radarr
http://VM_IP:3000   → Grafana
```

## What You Can Test

✅ All web interfaces and services
✅ Service configuration and integration
✅ Sonarr/Radarr automation
✅ Transmission downloads
✅ Monitoring dashboards
✅ Configuration changes (`nixos-rebuild`)
✅ Rollbacks
✅ User management
✅ Tailscale VPN

❌ Hardware transcoding (no GPU)
❌ Wake-on-LAN (VM limitation)

## Common Commands in VM

```bash
# SSH from your Mac (easier for copy/paste)
ssh admin@VM_IP

# Check services
sudo systemctl status plex
sudo systemctl status sonarr

# Make config changes
cd /etc/nixos-config
sudo nano modules/services/plex.nix

# Apply changes
sudo nixos-rebuild switch --flake /etc/nixos-config#vm-test

# Rollback if needed
sudo nixos-rebuild switch --rollback

# View logs
sudo journalctl -u plex -f
```

## Getting Started with Services

1. **Homepage**: http://VM_IP:3001
   - Overview of all services
   - Click through to configure each

2. **Plex**: http://VM_IP:32400/web
   - Sign in with Plex account
   - Skip library setup (or use small test files)

3. **Prowlarr**: http://VM_IP:9696
   - Add a test indexer (use a public one for testing)
   - Get API key from Settings

4. **Sonarr**: http://VM_IP:8989
   - Settings → Indexers → Add → Prowlarr
   - Settings → Download Clients → Add → Transmission

5. **Radarr**: http://VM_IP:7878
   - Same as Sonarr

6. **Transmission**: http://VM_IP:9091
   - Set password on first login

7. **Grafana**: http://VM_IP:3000
   - Login: admin/admin (change password)
   - Import Dashboard: ID 1860

## Testing Workflow

**Day 1**: Install, explore web interfaces
**Day 2**: Configure services, test integration
**Day 3**: Try a test download (Ubuntu ISO via torrent)
**Day 4**: Test configuration changes and rollbacks
**Day 5**: Practice everything you'll do on real server

## Troubleshooting

**Can't access services?**
```bash
# Check IP
ip addr show

# Check service
sudo systemctl status plex

# Check firewall
sudo iptables -L
```

**VM is slow?**
- Increase RAM to 16GB
- Give it more CPU cores
- Close other applications

**Out of space?**
```bash
sudo nix-collect-garbage -d
```

## When You Get Physical Server

The process is identical! Just use:
- `#home-server` instead of `#vm-test`
- Real hardware will have GPU transcoding
- Everything else works the same

## Why VM Testing is Great

1. **Zero risk** - Can't break anything
2. **Learn freely** - Experiment without consequences
3. **Fast iteration** - Snapshots let you try things quickly
4. **Practice** - Get comfortable before real deployment
5. **Validate config** - Ensure everything works
6. **Save time** - Hit the ground running with real hardware

## Next Steps

**Full Guide**: [documentation/08-vm-testing.md](documentation/08-vm-testing.md)

**After Testing**: When your server arrives, follow the same process but use `#home-server` instead of `#vm-test`!

---

**Pro Tip**: Take a VM snapshot after successful installation. If you break something, just restore the snapshot!

Happy testing! 🧪🚀
