# VM Testing Guide

This guide explains how to test your NixOS home server configuration in a virtual machine before deploying to physical hardware.

## Why Test in a VM?

- **Risk-free testing** - Experiment without affecting real hardware
- **Learn the system** - Get familiar with NixOS and services
- **Validate configuration** - Ensure everything works before deployment
- **Practice installation** - Run through the process multiple times
- **Test updates** - Try configuration changes safely

## What Works in a VM

✅ **All services** - Plex, Sonarr, Radarr, Transmission, etc.
✅ **Web interfaces** - Access all UIs from your host machine
✅ **Service integration** - Full automation pipeline works
✅ **Monitoring** - Grafana, Prometheus, Loki all functional
✅ **Tailscale VPN** - Remote access works in VM
✅ **Configuration testing** - Test nixos-rebuild and rollbacks
✅ **User management** - SSH, users, permissions
✅ **Network features** - Firewall, ports, etc.

## What Won't Work (or is Limited)

⚠️ **Hardware transcoding** - No Intel GPU passthrough (CPU transcode still works)
⚠️ **Wake-on-LAN** - VM limitation
⚠️ **Performance** - Slower than bare metal
⚠️ **Disk health monitoring** - SMART data may not be available

## VM Software Options for macOS

### Option 1: UTM (Recommended)

**Best for**: M1/M2 Macs and ease of use

1. **Download UTM**: https://mac.getutm.app/ (free)

2. **Download NixOS ISO**: https://nixos.org/download (Minimal ISO, ~900MB)

3. **Create VM**:
   - Open UTM → "Create a New Virtual Machine"
   - Select "Virtualize"
   - Operating System: "Linux"
   - Boot ISO: Select NixOS ISO
   - Architecture: ARM64 (M1/M2) or x86_64 (Intel Mac)
   - Memory: 8192 MB (8GB)
   - CPU Cores: 4
   - Storage: 60GB (for OS and services)

4. **Add Media Disk** (optional):
   - Settings → Drives → New Drive
   - Size: 50GB (for /srv/media)
   - Interface: VirtIO

5. **Network Settings**:
   - Network Mode: "Shared Network" (easiest)
   - Or "Bridged" for direct LAN access
   - Enable port forwarding for services

6. **Start VM** and proceed to installation

### Option 2: VirtualBox

**Best for**: Intel Macs and familiarity

1. **Install VirtualBox**:
   ```bash
   brew install --cask virtualbox
   ```

2. **Download NixOS ISO**: https://nixos.org/download

3. **Create VM**:
   - New → Name: "NixOS Home Server"
   - Type: Linux
   - Version: Other Linux (64-bit)
   - Memory: 8192 MB
   - Create virtual hard disk: 60 GB, VDI, Dynamically allocated

4. **Configure VM**:
   - Settings → Storage → Add optical drive → Select NixOS ISO
   - Settings → Storage → Add new SATA disk → 50GB (for media)
   - Settings → Network → Adapter 1 → Bridged Adapter
   - Settings → System → Enable EFI

5. **Start VM** and install

### Option 3: VMware Fusion

**Best for**: Professional features (has free personal license)

1. **Download VMware Fusion**: https://www.vmware.com/products/fusion/fusion-evaluation.html

2. **Download NixOS ISO**

3. **Create VM**:
   - File → New
   - Select NixOS ISO
   - Choose Linux → Other Linux 5.x kernel 64-bit
   - Customize Settings:
     - Memory: 8 GB
     - Processors: 4 cores
     - Hard Disk: 60 GB
     - Add → New Hard Disk → 50 GB (for media)
     - Network: Bridged

4. **Start VM**

## VM Installation Steps

### 1. Boot the VM

Boot from the NixOS ISO. You'll get a shell prompt.

### 2. Set Root Password (for SSH access during install)

```bash
passwd
# Set a temporary password
```

### 3. Enable SSH (Optional - easier to copy/paste)

```bash
systemctl start sshd

# Find VM's IP address
ip addr show
# Look for an IP like 192.168.x.x

# From your Mac, SSH to the VM
ssh root@192.168.x.x
```

### 4. Partition Disks

**For testing, simpler partitioning is fine:**

```bash
# List disks
lsblk

# Partition main disk (usually /dev/sda or /dev/vda)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB 100%

# Format
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2

# If you added a second disk for media
mkfs.ext4 -L media /dev/sdb
```

### 5. Mount Filesystems

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
mkdir -p /mnt/srv/media
mount /dev/disk/by-label/media /mnt/srv/media
```

### 6. Install Configuration

**Method A: Clone from GitHub** (if you've pushed your config)

```bash
nix-shell -p git
git clone https://github.com/yourusername/nixos-config.git /mnt/etc/nixos-config
```

**Method B: Copy from host via SSH** (if testing local changes)

On your Mac:
```bash
cd /Users/marcuspedersen/Code/nixos-config
tar czf - . | ssh root@VM_IP 'mkdir -p /mnt/etc/nixos-config && tar xzf - -C /mnt/etc/nixos-config'
```

### 7. Generate Hardware Config

```bash
cd /mnt/etc/nixos-config
nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/vm-test/hardware-configuration.nix
```

### 8. Install NixOS

```bash
nixos-install --flake /mnt/etc/nixos-config#vm-test
# Set root password when prompted
```

### 9. Reboot

```bash
reboot
```

Remove the ISO from VM settings before booting.

## Post-Installation VM Setup

### 1. Log In

```bash
# SSH from your Mac
ssh admin@VM_IP

# Or use VM console
# Login as admin (you'll need to set password first as root)
```

### 2. Set Admin Password (if needed)

```bash
# As root or via console
passwd admin
```

### 3. Configure Tailscale

```bash
sudo tailscale up
# Follow auth URL
```

### 4. Access Services

From your Mac's browser:

```
http://VM_IP:32400/web     # Plex
http://VM_IP:8989          # Sonarr
http://VM_IP:7878          # Radarr
http://VM_IP:9696          # Prowlarr
http://VM_IP:9091          # Transmission
http://VM_IP:3000          # Grafana
http://VM_IP:3001          # Homepage
```

## Testing Workflow

### 1. Test Service Installation

Check all services are running:
```bash
sudo systemctl status plex
sudo systemctl status sonarr
sudo systemctl status radarr
sudo systemctl status transmission
sudo systemctl status grafana
```

### 2. Test Web Access

Open each web interface and verify it loads.

### 3. Test Configuration Changes

```bash
# Make a change to configuration
nano /etc/nixos-config/modules/services/plex.nix

# Rebuild
sudo nixos-rebuild switch --flake /etc/nixos-config#vm-test

# Verify change took effect
```

### 4. Test Rollback

```bash
# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Verify services still work
```

### 5. Test Service Integration

1. Configure Prowlarr with a test indexer
2. Add Prowlarr to Sonarr/Radarr
3. Add Transmission as download client
4. Try a test download (use a legal torrent like Ubuntu ISO)

### 6. Test Monitoring

1. Open Grafana at http://VM_IP:3000
2. Login (admin/admin, change password)
3. Import dashboard ID: 1860 (Node Exporter Full)
4. Verify metrics are flowing

## VM-Specific Adjustments

### Reduce Resource Usage

The VM configuration already has reduced memory limits. If you need to reduce further:

```nix
# In hosts/vm-test/configuration.nix
systemd.services.plex.serviceConfig.MemoryMax = lib.mkForce "1G";
systemd.services.transmission.serviceConfig.MemoryMax = lib.mkForce "512M";
```

### Port Forwarding (if using NAT network)

In UTM/VirtualBox, forward ports:
- 22 (SSH) → 2222
- 32400 (Plex) → 32400
- 8989 (Sonarr) → 8989
- 3001 (Homepage) → 3001
- etc.

Then access via: `http://localhost:32400/web`

### Shared Folders (Optional)

For testing with real media files:

**UTM**: Settings → Sharing → Enable shared folder
**VirtualBox**: Settings → Shared Folders → Add folder

Mount in NixOS:
```bash
# For VirtualBox
sudo mount -t vboxsf ShareName /srv/media/test

# For UTM
sudo mount -t 9p -o trans=virtio share /srv/media/test
```

## Testing Checklist

Use this to verify everything works:

- [ ] VM boots successfully
- [ ] Can SSH into VM
- [ ] All services start on boot
- [ ] Can access all web interfaces
- [ ] Sonarr can search (with test indexer)
- [ ] Radarr can search
- [ ] Transmission can download
- [ ] Plex shows media (test files)
- [ ] Grafana displays metrics
- [ ] Tailscale connection works
- [ ] Can rebuild configuration
- [ ] Rollback works
- [ ] Homepage shows all services
- [ ] Logs are being collected

## Common VM Issues

### VM is slow

- Increase RAM to 16GB if available
- Increase CPU cores to 6-8
- Use SSD for VM storage
- Disable services you're not testing

### Can't access web interfaces

```bash
# Check service is running
sudo systemctl status plex

# Check firewall
sudo iptables -L -n | grep 32400

# Check if listening
sudo ss -tlnp | grep 32400

# Try from VM itself
curl http://localhost:32400
```

### Out of disk space

```bash
# Clean up
sudo nix-collect-garbage -d
sudo nix-store --optimize

# Or increase VM disk size in settings
```

### Services won't start

```bash
# Check logs
sudo journalctl -u plex -n 50

# Check permissions
ls -la /srv/media
ls -la /var/lib/plex
```

## Differences from Physical Server

| Feature | VM | Physical Server |
|---------|----|--------------------|
| GPU Transcoding | ❌ No | ✅ Yes |
| Performance | ⚠️ Slower | ✅ Full Speed |
| Wake-on-LAN | ❌ No | ✅ Yes |
| SMART Monitoring | ⚠️ Limited | ✅ Full |
| Service Features | ✅ All Work | ✅ All Work |
| Configuration | ✅ Identical | ✅ Identical |
| Rollback | ✅ Yes | ✅ Yes |

## After VM Testing

Once you're comfortable with the system:

1. **Document any changes** you made during testing
2. **Update configuration files** with your customizations
3. **Commit to git**: `git add . && git commit -m "Tested in VM"`
4. **Push to GitHub** (if using)
5. **Deploy to physical server** when it arrives

The configuration will be nearly identical - just use `#home-server` instead of `#vm-test` during installation.

## Snapshot Before Testing

Most VM software supports snapshots:

```
Take snapshot: "Fresh Install"
↓
Test configuration changes
↓
Something breaks?
↓
Restore snapshot "Fresh Install"
```

This lets you experiment freely without risk.

## Learning Path

Suggested order for VM testing:

1. **Week 1**: Install, explore web interfaces, understand service layout
2. **Week 2**: Configure services, test downloads, set up monitoring
3. **Week 3**: Practice configuration changes and rebuilds
4. **Week 4**: Test integration, automation, fine-tune settings

By the time your physical server arrives, you'll be an expert!

## Resources

- **VM Software**:
  - UTM: https://mac.getutm.app/
  - VirtualBox: https://www.virtualbox.org/
  - VMware Fusion: https://www.vmware.com/products/fusion.html

- **NixOS**:
  - Installation Manual: https://nixos.org/manual/nixos/stable/
  - Virtual Machines Guide: https://nixos.wiki/wiki/NixOS_Virtualization

- **Testing Tips**:
  - Use small test media files
  - Use public domain torrents for testing
  - Take frequent snapshots
  - Document your learnings

## Tips for Effective VM Testing

1. **Use Snapshots**: Take snapshots before major changes
2. **Start Simple**: Don't configure everything at once
3. **Test Incrementally**: Add one service at a time
4. **Document**: Keep notes on what works/doesn't work
5. **Practice Rebuilds**: Get comfortable with `nixos-rebuild`
6. **Test Rollbacks**: Intentionally break things and recover
7. **Use Real Scenarios**: Try actual workflows you'll use
8. **Time It**: Note how long operations take (slower in VM)

## Conclusion

VM testing is an excellent way to:
- Learn NixOS without risk
- Test your configuration thoroughly
- Practice installation and deployment
- Validate service integration
- Understand the system before hardware arrives

By the time your physical server is ready, you'll be confident in deploying and managing your home server! 🚀

**Next**: When ready for physical deployment, follow `documentation/01-installation.md` but use `#home-server` instead of `#vm-test`.
