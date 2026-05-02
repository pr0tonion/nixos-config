# Day-to-Day Usage

## Rebuild commands

From the repo directory on the target machine:

```bash
# Apply changes immediately
sudo nixos-rebuild switch --flake .#home-computer

# Test without touching boot menu (reverts on reboot)
sudo nixos-rebuild test --flake .#home-computer

# Stage for next boot only
sudo nixos-rebuild boot --flake .#home-computer
```

Bash aliases (available after first login):

Aliases on **home-computer** (defined in `home/admin-desktop.nix`):

| Alias | Expands to |
|-------|-----------|
| `nrs` | `sudo nixos-rebuild switch --flake .#home-computer` |
| `nrt` | `sudo nixos-rebuild test --flake .#home-computer` |
| `nrb` | `sudo nixos-rebuild boot --flake .#home-computer` |
| `nfu` | `nix flake update` |

Aliases on **home-server / vm-test** (defined in `home/admin-server.nix`)
target `.#home-server` instead.

---

## Remote deploy (from macOS)

```bash
nixos-rebuild switch --flake .#home-server \
  --target-host admin@home-server --use-remote-sudo
```

---

## Adding a package

System-wide: add to `modules/base.nix` or a relevant module
(e.g. `modules/desktop/applications.nix` for desktop apps).
User-level: add to `home.packages` in `home/admin-desktop.nix`
(or `home/admin-server.nix` for server hosts).

Rebuild after any change.

---

## First-login checklist (home-computer)

1. **Change the admin password** — the install ships with `initialPassword = "admin"`:
   ```bash
   passwd
   ```
2. **Enable Krohnkite** (tiling window manager):
   System Settings → Window Management → KWin Scripts → toggle on **Krohnkite** → Apply.
   Default shortcuts: `Meta+T` to tile, `Meta+J/K` to navigate, `Meta+H/L` to resize.
3. **Generate an SSH key** and add it to `modules/desktop/users.nix`:
   ```bash
   ssh-keygen -t ed25519 -C "marcus.pedersen95@gmail.com"
   cat ~/.ssh/id_ed25519.pub
   ```
   Paste under `users.users.admin.openssh.authorizedKeys.keys`, then `nrs`.
4. **In Steam**: Settings → Compatibility → "Enable Steam Play for all other titles"
   to turn on Proton for non-native games.

---

## Updating flake inputs

```bash
nix flake update         # update all inputs
nix flake update nixpkgs # update one input
sudo nixos-rebuild switch --flake .#home-computer
```

---

## Rollback

```bash
sudo nixos-rebuild switch --rollback
```

Or at boot: select a previous generation from the systemd-boot menu.

---

## Garbage collection

```bash
# Remove generations older than 30 days
sudo nix-collect-garbage --delete-older-than 30d

# Also clean up boot entries
sudo nixos-rebuild boot --flake .#home-computer
```

---

## Validate syntax without building

```bash
nix flake check
```

---

## Adding a new module

1. Create `modules/<category>/<name>.nix`
2. Add it to the host's module list in `flake.nix`
3. Open any required firewall ports inside the module itself

---

## SSH key management

Keys live under `users.users.admin.openssh.authorizedKeys.keys` in:
- `modules/desktop/users.nix` — for home-computer
- `modules/users.nix` — for home-server / vm-test

Password auth is disabled on all hosts.
