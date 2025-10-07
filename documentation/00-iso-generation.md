# ISO Generation Guide

## Building the Installation ISO

This guide explains how to build a bootable NixOS ISO for installing on your home server.

## Prerequisites

- A Linux machine or NixOS system (can't build on macOS/Windows directly)
- Nix package manager installed
- About 2-3 GB of free disk space

## Method 1: Using the Flake Configuration (Recommended)

From the repository root:

```bash
# Build the installer ISO
nix build .#nixosConfigurations.installer.config.system.build.isoImage

# The ISO will be created in the result directory
ls -lh result/iso/*.iso

# Copy to a more accessible location
cp result/iso/*.iso ~/nixos-installer.iso
```

## Method 2: Using nixos-generate

If you prefer, you can use `nixos-generate`:

```bash
# Install nixos-generate
nix-shell -p nixos-generators

# Generate ISO
nixos-generate -f install-iso -c hosts/home-server/configuration.nix
```

## Method 3: Standard NixOS ISO

Alternatively, download the standard NixOS ISO and use it for installation:

1. Go to https://nixos.org/download.html
2. Download the "Minimal ISO image"
3. This is simpler but requires manual configuration after installation

## Writing ISO to USB

### On Linux:

```bash
# Find your USB device (be careful!)
lsblk

# Write ISO to USB (replace /dev/sdX with your USB device)
sudo dd if=nixos-installer.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

### On macOS:

```bash
# Find your USB device
diskutil list

# Unmount the USB drive (replace N with your disk number)
diskutil unmountDisk /dev/diskN

# Write ISO to USB
sudo dd if=nixos-installer.iso of=/dev/rdiskN bs=4m
sudo sync

# Eject the USB
diskutil eject /dev/diskN
```

### On Windows:

Use one of these tools:
- **Rufus** (recommended): https://rufus.ie/
- **Etcher**: https://www.balena.io/etcher/
- **Ventoy**: https://www.ventoy.net/

## Boot from USB

1. Insert the USB drive into your home server
2. Enter BIOS/UEFI (usually F2, F12, DEL, or ESC during boot)
3. Change boot order to boot from USB first
4. Save and reboot

## Next Steps

After booting from the USB, proceed to [01-installation.md](01-installation.md) for installation instructions.

## Troubleshooting

### ISO build fails with "error: attribute 'isoImage' missing"

The flake configuration might need adjustment. Try using the standard NixOS ISO instead.

### USB won't boot

- Ensure UEFI/Legacy boot mode is correct
- Try a different USB port
- Verify the ISO was written correctly
- Check if Secure Boot needs to be disabled

### Out of disk space during build

Building the ISO requires about 2-3 GB. Free up space or use a different partition.
