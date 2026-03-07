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
Shared across hosts. Each module is self-contained and opens its own firewall ports.
- `base.nix` — system packages, smartd, journald limits, fstrim
- `networking.nix` — firewall, WoL, Avahi/mDNS
- `users.nix` — `admin` (wheel), `media` (gid 1500), `vpn`, `monitoring` system users; `/srv/media` directory tree via `systemd.tmpfiles`
- `services/` — one file per service (plex, media-automation, torrent, vpn, dashboard, monitoring)
- `maintenance/cleanup.nix` — scheduled nix GC and media cleanup timers

### Home Manager (`home/admin.nix`)
Manages the `admin` user environment: bash aliases (`nrs`, `nrt`, `nrb`, `nfu`), starship prompt, neovim (config cloned from GitHub on first activation), git, ssh.

### Flake inputs
- `nixpkgs` → `nixos-25.05`
- `nixpkgs-unstable` → available as `pkgs-unstable` in all modules via `specialArgs`
- `home-manager` → `release-25.05`, follows main nixpkgs

## home-computer Host

Currently a skeleton (`hosts/home-computer/configuration.nix`). It only pulls in `base.nix`, `networking.nix`, and `users.nix` — no service modules. This is the host to expand. It has no `hardware-configuration.nix` yet; one must be generated on the target machine with:
```bash
sudo nixos-generate-config --show-hardware-config > hosts/home-computer/hardware-configuration.nix
```
Then add it to the `modules` list in `flake.nix` under `home-computer`.

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

Add your public key in `modules/users.nix` under `users.users.admin.openssh.authorizedKeys.keys`. Password auth is disabled; SSH key is required to log in.
