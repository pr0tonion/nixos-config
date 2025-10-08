# Testing NixOS Configuration with VirtualBox on Windows

This guide shows how to test your NixOS home server configuration in a VirtualBox VM, accessible via its own IP address on your network.

## Prerequisites

- Windows 10/11
- At least 8GB RAM (16GB recommended for comfortable testing)
- 30GB free disk space
- VirtualBox installed
- Your network allows DHCP (most home networks do)

## Step 1: Install VirtualBox

1. Download VirtualBox from: https://www.virtualbox.org/wiki/Downloads
2. Download "VirtualBox platform packages" for Windows hosts
3. Run the installer with default settings
4. Reboot if prompted

## Step 2: Download NixOS ISO

1. Go to: https://nixos.org/download.html#nixos-iso
2. Download **"Minimal ISO image"** for **x86_64-linux**
3. The file will be named something like: `nixos-minimal-24.05-x86_64-linux.iso`
4. Save it to your Downloads folder

## Step 3: Create a New Virtual Machine

1. Open **VirtualBox**
2. Click **"New"** button

### Basic Settings:
- **Name**: `NixOS-Home-Server-Test`
- **Type**: `Linux`
- **Version**: `Other Linux (64-bit)`
- Click **Next**

### Memory:
- **RAM**: `4096 MB` (4GB minimum, 8192 MB if you have 16GB+ RAM)
- Click **Next**

### Hard Disk:
- Select **"Create a virtual hard disk now"**
- Click **Create**

### Hard Disk Type:
- Select **"VDI (VirtualBox Disk Image)"**
- Click **Next**

### Storage:
- Select **"Dynamically allocated"**
- Click **Next**

### Disk Size:
- Set to **40 GB** (minimum for testing all services)
- Click **Create**

## Step 4: Configure VM Settings

Right-click the VM → **Settings**

### System Settings:

**Motherboard tab:**
- **Boot Order**: Check "Hard Disk" and "Optical" (uncheck Floppy)
- **Extended Features**: Enable "EFI (special OSes only)" ✓

**Processor tab:**
- **Processors**: `2 CPUs` (or more if you have 6+ cores)
- **Extended Features**: Enable "Enable PAE/NX" ✓

### Storage Settings:

1. Under **Controller: IDE**, click **"Empty"**
2. Click the **disk icon** on the right → **"Choose a disk file"**
3. Select the NixOS ISO you downloaded
4. Click **OK**

### Network Settings:

**Adapter 1:**
- **Enable Network Adapter**: ✓ (checked)
- **Attached to**: Change from "NAT" to **"Bridged Adapter"**
- **Name**: Select your active network adapter (usually "Ethernet" or "Wi-Fi")
- **Promiscuous Mode**: `Allow All`
- Click **OK**

## Step 5: Start the VM and Boot NixOS

1. Select your VM
2. Click **Start** (green arrow)
3. The VM will boot from the NixOS ISO
4. Wait for the boot process to complete
5. You'll see a login prompt: `nixos login:`

### Log in:
- Username: `nixos`
- Password: (press Enter - no password needed)

## Step 6: Set Up SSH Access

Once logged into the VM console:

```bash
# Set a password for the nixos user to enable SSH
sudo passwd nixos
# Enter a simple password like: test1234

# Find the VM's IP address
ip addr show
```

Look for the IP address under `eth0` or `enp0s3`. It will look like:
- `192.168.1.xxx` or
- `192.168.0.xxx` or
- `10.0.0.xxx`

**Write down this IP address!** Example: `192.168.1.150`

```bash
# Start SSH service
sudo systemctl start sshd
```

## Step 7: Connect via SSH from Windows

### Option A: Using Windows Terminal/PowerShell

Open PowerShell or Windows Terminal:

```powershell
# Replace 192.168.1.150 with your VM's IP address
ssh nixos@192.168.1.150
# Password: test1234 (or whatever you set)
```

### Option B: Using WSL

If you have WSL installed:

```bash
ssh nixos@192.168.1.150
```

### Option C: Using PuTTY

1. Download PuTTY from: https://www.putty.org/
2. Run PuTTY
3. Enter the VM's IP address
4. Port: 22
5. Click "Open"
6. Login as: `nixos`
7. Password: `test1234`

## Step 8: Partition and Format Disks

In your SSH session to the VM:

```bash
# Switch to root
sudo -i

# Partition the disk (GPT for UEFI)
parted /dev/sda -- mklabel gpt
parted /dev/sda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/sda -- set 1 esp on
parted /dev/sda -- mkpart primary 512MiB -8GiB
parted /dev/sda -- mkpart primary linux-swap -8GiB 100%

# Format partitions
mkfs.fat -F 32 -n boot /dev/sda1
mkfs.ext4 -L nixos /dev/sda2
mkswap -L swap /dev/sda3

# Enable swap
swapon /dev/sda3

# Mount filesystems
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Create media storage directory (for your services)
mkdir -p /mnt/srv/media

# Verify the EFI partition is mounted correctly (prevents boot issues)
mount | grep boot
lsblk -f
# You should see /dev/sda1 mounted at /mnt/boot with vfat filesystem
```

## Step 9: Clone Your NixOS Configuration

```bash
# Install git (temporary, in the live environment)
nix-shell -p git

# Clone your configuration
# Replace YOUR-USERNAME with your GitHub username
git clone https://github.com/pr0tonion/nixos-config.git /mnt/etc/nixos

# Generate hardware configuration
nixos-generate-config --root /mnt

# Copy the generated hardware config to the vm-test host
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/nixos-config/hosts/vm-test/

# Verify the hardware config looks correct
cat /mnt/etc/nixos/nixos-config/hosts/vm-test/hardware-configuration.nix
```

## Step 10: Install NixOS

```bash
# Navigate to your config directory
cd /mnt/etc/nixos/nixos-config

# Install NixOS using your vm-test configuration
nixos-install --flake .#vm-test

# This will take 10-30 minutes depending on your internet speed
# It will download and build all the packages

# When prompted, set a ROOT password (you can use: admin123)
# When prompted again, set a password for the ADMIN user (use: admin123)
```

**Wait for installation to complete.** You'll see messages about downloading packages, building derivations, etc.

### Verify Bootloader Installation

Before rebooting, verify that the bootloader was installed correctly:

```bash
# Check that EFI boot files were created
ls -la /mnt/boot/EFI/
# You should see directories like "BOOT" and "systemd" or "nixos"

# If the directory is empty or doesn't exist, the bootloader wasn't installed
# This means you'll get a "no bootable device" error when you reboot
```

**If the EFI directory is empty or doesn't exist:**

```bash
# First, verify the boot partition is still mounted
mount | grep boot
# Should show: /dev/sda1 on /mnt/boot type vfat

# If not mounted, remount it:
mount /dev/disk/by-label/boot /mnt/boot

# Check your hardware configuration has bootloader settings
cat /mnt/etc/nixos/nixos-config/hosts/vm-test/hardware-configuration.nix | grep -A 3 "boot.loader"

# You should see either:
# boot.loader.systemd-boot.enable = true;
# boot.loader.efi.canTouchEfiVariables = true;
# OR
# boot.loader.grub.enable = true;
# boot.loader.grub.efiSupport = true;

# If the bootloader config is missing, you need to add it to your vm-test configuration
# Then run nixos-install again:
cd /mnt/etc/nixos/nixos-config
nixos-install --flake .#vm-test --no-root-passwd

# The --no-root-passwd flag skips password prompts since you already set them
# After this completes, verify again:
ls -la /mnt/boot/EFI/
```

## Step 11: Reboot into Installed System

```bash
# Exit root shell
exit

# Reboot
reboot
```

The VM will restart. You'll see GRUB bootloader, then NixOS will boot.

## Step 12: Remove the ISO

Before the VM finishes rebooting:

1. In VirtualBox, right-click the running VM → **Settings**
2. Go to **Storage**
3. Click the NixOS ISO under **Controller: IDE**
4. Click the disk icon → **Remove Disk from Virtual Drive**
5. Click **OK**

Let the VM finish booting.

## Step 13: Log In and Verify

### Option A: Via VirtualBox Console

At the login prompt:
- Username: `admin`
- Password: (the password you set during installation)

### Option B: Via SSH (Recommended)

The VM should have the same IP address, or check in the console with:
```bash
ip addr show
```

From Windows:
```powershell
ssh admin@192.168.1.150
```

## Step 14: Access Services from Windows

Open your web browser on Windows and go to:

- **Grafana**: `http://192.168.1.150:3000`
  - Username: `admin`
  - Password: `admin` (change on first login)

- **Prometheus**: `http://192.168.1.150:9090`

- **Plex**: `http://192.168.1.150:32400/web`

- **Transmission**: `http://192.168.1.150:9091`
  - Username: `admin`
  - Password: (set in config or via transmission-remote)

- **Homepage Dashboard**: `http://192.168.1.150:8082`

Replace `192.168.1.150` with your VM's actual IP address.

## Step 15: Test Services

### Check System Status

```bash
# SSH into the VM
ssh admin@192.168.1.150

# Check all services are running
sudo systemctl status plex
sudo systemctl status grafana
sudo systemctl status prometheus
sudo systemctl status transmission
sudo systemctl status homepage-dashboard

# Check logs if any service failed
sudo journalctl -u plex -n 50
```

### Add Test Media

```bash
# Create some test directories
sudo mkdir -p /srv/media/movies/TestMovie
sudo mkdir -p /srv/media/tv/TestShow

# Set proper permissions
sudo chown -R media:media /srv/media/

# You can now configure Plex to scan /srv/media/movies and /srv/media/tv
```

## Making Changes and Testing

### 1. Edit Configuration on Windows

Using WSL or your preferred editor:

```bash
cd ~/code/nixos-config
# Make your changes
code modules/services/plex.nix
```

### 2. Commit and Push to GitHub

```bash
git add .
git commit -m "Test: update plex configuration"
git push
```

### 3. Pull and Rebuild on VM

```bash
# SSH to VM
ssh admin@192.168.1.150

# Pull changes
cd /etc/nixos/nixos-config
sudo git pull

# Rebuild and switch
sudo nixos-rebuild switch --flake .#vm-test

# Check if services restarted correctly
sudo systemctl status plex
```

### Quick Rebuild Script

On your Windows machine (in WSL or PowerShell), create a script:

**WSL/PowerShell: `rebuild-vm.ps1`**
```powershell
# Save as rebuild-vm.ps1
ssh admin@192.168.1.150 "cd /etc/nixos/nixos-config && sudo git pull && sudo nixos-rebuild switch --flake .#vm-test"
```

Run it:
```powershell
.\rebuild-vm.ps1
```

## Troubleshooting

### Cannot SSH to VM

1. Check VM is running: Should show in VirtualBox
2. Check IP address: Login via VirtualBox console, run `ip addr show`
3. Check firewall: Your config should allow port 22
4. Check SSH service: `sudo systemctl status sshd`

### Cannot Access Web Services

1. Check service is running: `sudo systemctl status grafana`
2. Check firewall ports are open: `sudo nix-shell -p netcat --run "nc -zv localhost 3000"`
3. Check from VM itself: `curl http://localhost:3000`
4. Verify IP address hasn't changed
5. Check Windows Firewall isn't blocking connections

### VM is Slow

1. Allocate more RAM: Settings → System → Base Memory (8192 MB)
2. Allocate more CPUs: Settings → System → Processor (4 CPUs)
3. Enable 3D Acceleration: Settings → Display → Enable 3D Acceleration

### Services Won't Start

Check logs:
```bash
# General system log
sudo journalctl -xe

# Specific service
sudo journalctl -u plex -n 100

# Check what failed during boot
sudo systemctl --failed
```

### IP Address Keeps Changing

Configure a static IP in the VM:

```bash
sudo nano /etc/nixos/nixos-config/hosts/vm-test/configuration.nix
```

Add:
```nix
networking.interfaces.enp0s3.ipv4.addresses = [{
  address = "192.168.1.150";
  prefixLength = 24;
}];
networking.defaultGateway = "192.168.1.1";
networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
```

Then rebuild:
```bash
sudo nixos-rebuild switch --flake .#vm-test
```

## Snapshot Your Working VM

Once everything is working:

1. Shut down the VM: `sudo poweroff`
2. In VirtualBox, select your VM
3. Click **Snapshots** (top right)
4. Click **Take** snapshot
5. Name it: "Working Base Configuration"

Now you can experiment and restore to this snapshot if something breaks!

## Next Steps

### When You Get Your Physical Server:

1. Download the standard NixOS ISO
2. Boot your server from it
3. Follow the same installation steps, but use `.#home-server` instead of `.#vm-test`
4. Copy any working configurations you tested in the VM

### Differences Between VM and Real Hardware:

- **Hardware config**: Will be different (real network cards, disk controllers)
- **GPU transcoding**: VM won't have GPU passthrough, real server will
- **Performance**: Real hardware will be much faster
- **Network**: Real server will have its own permanent IP

## Cleaning Up

When done testing:

1. **Export VM** (to keep it):
   - File → Export Appliance
   - Select your VM
   - Save as `.ova` file

2. **Delete VM** (to free space):
   - Right-click VM → Remove
   - Select "Delete all files"

---

**You're ready to test!** Your NixOS configuration is now running in a VM accessible from your Windows machine at `http://VM-IP-ADDRESS:PORT`.
