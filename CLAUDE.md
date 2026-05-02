# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A NixOS flake-based configuration managing multiple hosts: `home-server` (media server), `home-computer` (desktop, actively being developed), and `vm-test` (mirrors home-server for testing). Pinned to `nixos-25.05` with `nixpkgs-unstable` available as `pkgs-unstable` for newer packages.

## Key Commands

All commands run on the target NixOS machine (or via SSH with `--target-host`).

```bash
# Build and switch (primary workflow)
sudo nixos-rebuild switch --flake .#home-computer
sudo nixos-rebuild switch --flake .#home-server

# Test a change without committing to boot menu (safe - reverts on reboot)
sudo nixos-rebuild test --flake .#home-computer

# Validate syntax without building
nix flake check

# Update all flake inputs
nix flake update

# Remote deploy from macOS to a NixOS host
nixos-rebuild switch --flake .#home-server --target-host admin@home-server --use-remote-sudo

# Rollback
sudo nixos-rebuild switch --rollback

# Garbage collect old generations
sudo nix-collect-garbage --delete-older-than 30d
```

## Architecture

### Host Configs (`hosts/<name>/configuration.nix`)
Host-specific settings only: hostname, timezone/locale (`Europe/Oslo`, Norwegian keyboard), bootloader, SSH, firewall base rules. Hardware config lives alongside it in `hardware-configuration.nix`.

### Modules (`modules/`)
Each module is self-contained and opens its own firewall ports.
- `base.nix` — system packages, smartd, journald limits, fstrim (all hosts)
- `networking.nix` — firewall, WoL, Avahi/mDNS (server only — uses systemd-networkd, conflicts with NetworkManager)
- `users.nix` — server `admin` + `media`/`vpn`/`monitoring` system users; `/srv/media` tree via `systemd.tmpfiles`
- `services/` — one file per service (plex, media-automation, torrent, vpn, dashboard, monitoring)
- `maintenance/cleanup.nix` — scheduled nix GC and media cleanup timers
- `desktop/` — home-computer-only modules: `users.nix` (desktop admin), `gpu.nix`, `audio.nix`, `bluetooth.nix`, `fonts.nix`, `plasma.nix`, `applications.nix`

### Home Manager
Two profiles, one per use case:
- `home/admin-server.nix` — server admin (`nrs` aliases target `home-server`)
- `home/admin-desktop.nix` — desktop admin (`nrs` aliases target `home-computer`, plus direnv, dev CLI tools, Nix LSP)
Both share starship, neovim (config cloned from GitHub on first activation), and git identity.

### Flake inputs
- `nixpkgs` → `nixos-25.05`
- `nixpkgs-unstable` → available as `pkgs-unstable` in all modules via `specialArgs`
- `home-manager` → `release-25.05`, follows main nixpkgs

## home-computer Host

Desktop running KDE Plasma 6 on Wayland. AMD Ryzen 5 7600X + RX 5700 XT, 32GB RAM, ASUS TUF B650-PLUS WIFI. Steam (with gamescope session + Proton via Steam itself), gamemode, ADB for Android Studio, Bluetooth, Avahi for `.local` resolution.

Admin user `initialPassword = "admin"` — must be changed with `passwd` immediately after first login. SSH password auth is disabled; add a key to `modules/desktop/users.nix` once generated on the desktop.

`hardware-configuration.nix` is a stub (`{...}: {}`) — the real one is generated on the target machine during install (see `run-documentation/install_on_fresh_computer.md`).

## Adding a New Module

1. Create `modules/<category>/<name>.nix`
2. Add it to the relevant host's module list in `flake.nix`
3. Open any required firewall ports inside the module itself (not in the host config)

## Service Data Locations

| Service | State path |
|---------|-----------|
| Plex | `/var/lib/plex` |
| Sonarr | `/var/lib/sonarr` |
| Radarr | `/var/lib/radarr` |
| Transmission | `/var/lib/transmission` |
| Grafana | `/var/lib/grafana` |
| Media files | `/srv/media` (owner: `media:media`) |

## SSH Key Setup

Add your public key under `users.users.admin.openssh.authorizedKeys.keys` in:
- `modules/users.nix` — for home-server / vm-test
- `modules/desktop/users.nix` — for home-computer

Password auth is disabled on every host. The desktop admin has `initialPassword = "admin"` for first console login only — change it with `passwd` and add an SSH key.
