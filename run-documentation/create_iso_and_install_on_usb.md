# Get the NixOS Installer ISO and Flash to USB

> **Note:** Building the ISO locally from the flake requires an x86_64-linux builder.
> On Apple Silicon Macs, just download the official ISO instead — it has everything needed.

---

## 1. Download the official NixOS minimal ISO

Go to https://nixos.org/download and download the **Minimal ISO** for x86_64-linux,
or use curl directly (check the site for the current release URL):

```bash
curl -L -o nixos-minimal.iso \
  "https://channels.nixos.org/nixos-25.05/latest-nixos-minimal-x86_64-linux.iso"
```

---

## 2. Find your USB drive

```bash
# macOS
diskutil list
```

Note the device (e.g. `/dev/disk4`). Double-check — `dd` will wipe whatever you target.

---

## 3. Flash to USB

```bash
# Unmount first
diskutil unmountDisk /dev/disk4

# Flash (use /dev/rdisk for raw disk — much faster on macOS)
sudo dd if=nixos-minimal.iso of=/dev/rdisk4 bs=4m status=progress
sync
```

---

## 4. Boot from USB

Plug into the target machine. Enter BIOS/UEFI (usually F2, F12, or Del)
and select the USB as the boot device.

Once booted, follow [install_on_fresh_computer.md](./install_on_fresh_computer.md).

---

## Building the ISO from the flake (Linux only)

If you have access to an x86_64-linux machine with Nix:

```bash
nix build .#nixosConfigurations.installer.config.system.build.isoImage
# ISO is at ./result/iso/nixos-*.iso
```
