# Installing NixOS on a Fresh Computer (home-computer)

Boot from a NixOS live ISO, then follow these steps.

---

## 1. Identify drives

```bash
lsblk -o NAME,SIZE,MODEL
```

Find the **2TB NVMe** (NixOS, ~1.8T) and the **1TB NVMe** (~931G).
Note the device names, e.g. `nvme0n1` and `nvme1n1`.

---

## 1b. (Optional) Wipe the 1TB drive

Skip this if you want to keep the existing Windows install as a fallback.
Only run this once you've **triple-checked** which device is the 1TB —
running `wipefs` on the wrong drive destroys your install target.

```bash
# Confirm 1TB device
lsblk -o NAME,SIZE,MODEL

# Wipe partition table and filesystem signatures
sudo wipefs -a /dev/nvme1n1   # ← replace with the actual 1TB device

# Optional: also zero the first 100 MB to kill any stale boot sectors
sudo dd if=/dev/zero of=/dev/nvme1n1 bs=1M count=100
```

The drive is now blank. NixOS won't touch it (it's not in
`hardware-configuration.nix`). To install Windows on it later, boot a
Windows install USB — the installer will partition it itself. Note that
Windows installers sometimes overwrite the systemd-boot entry on the
shared EFI partition; recover from a NixOS live ISO with `bootctl install`
if that happens.

---

## 2. Partition the 2TB NVMe

```bash
sudo gdisk /dev/nvme0n1
```

Inside gdisk:
```
o           # new GPT table (wipes disk — confirm with y)
n → +512M → EF00    # p1: EFI
n → +32G  → 8200    # p2: swap (matches 32GB RAM, needed for hibernation)
n → default → 8300  # p3: root (rest of disk)
w                   # write and exit
```

---

## 3. Format partitions

```bash
sudo mkfs.fat -F32 /dev/nvme0n1p1
sudo mkswap -L swap /dev/nvme0n1p2
sudo mkfs.ext4 -L nixos /dev/nvme0n1p3
```

---

## 4. Mount

```bash
sudo mount /dev/nvme0n1p3 /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot
sudo swapon /dev/nvme0n1p2
```

---

## 5. Clone the config repo

```bash
sudo nix-shell -p git --run "git clone https://github.com/pr0tonion/nixos-config /mnt/etc/nixos-config"
```

---

## 6. Generate hardware config

```bash
sudo nixos-generate-config --root /mnt
sudo cp /mnt/etc/nixos/hardware-configuration.nix \
        /mnt/etc/nixos-config/hosts/home-computer/hardware-configuration.nix
```

Then commit it from macOS (after install) or directly if git is available:
```bash
cd /mnt/etc/nixos-config
git add hosts/home-computer/hardware-configuration.nix
git commit -m "Add hardware-configuration.nix for home-computer"
```

---

## 7. Install

```bash
sudo nixos-install --flake /mnt/etc/nixos-config#home-computer --no-root-passwd
```

The admin user's `initialPassword` is set to `admin` in
`modules/desktop/users.nix`. Change it immediately after first login with:
```bash
passwd
```

---

## 8. Reboot

```bash
sudo reboot
```

Remove the USB. The system boots from the 2TB NVMe. Confirm with:
```bash
lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT
```

---

## 9. Add your SSH key (after first login)

Generate a key on the desktop, then add it to
`modules/desktop/users.nix` under
`users.users.admin.openssh.authorizedKeys.keys` for SSH-based remote access.
Password auth is disabled, so until a key is added, login is console-only.

```bash
ssh-keygen -t ed25519 -C "marcus.pedersen95@gmail.com"
cat ~/.ssh/id_ed25519.pub
```

After editing the module, rebuild:
```bash
cd /etc/nixos-config
sudo nixos-rebuild switch --flake .#home-computer
```
