# sync-desktop

Reads `home-computer-applications.txt` and `home-computer-hardware.txt` and updates the home-computer NixOS configuration to match.

## What this command does

1. Reads `home-computer-applications.txt` — updates `modules/desktop/applications.nix` to reflect the current application list
2. Reads `home-computer-hardware.txt` — checks if hardware has changed and updates `modules/desktop/gpu.nix` and `hosts/home-computer/configuration.nix` accordingly (CPU microcode, GPU drivers, kernel modules, WiFi firmware)
3. Reports what changed and what (if anything) requires a manual step

## Steps

### Step 1 — Read spec files
Read both spec files in full:
- `home-computer-applications.txt`
- `home-computer-hardware.txt`

### Step 2 — Read current NixOS config files
Read the files you will potentially modify:
- `modules/desktop/applications.nix`
- `modules/desktop/gpu.nix`
- `hosts/home-computer/configuration.nix`

### Step 3 — Reconcile applications
Compare the application list in `home-computer-applications.txt` against `modules/desktop/applications.nix`.

Rules for mapping applications to Nix:
- Use the exact nixpkgs attribute name (e.g. `google-chrome`, `vscode`, `android-studio`, `nodejs`, `python313`)
- If an application belongs in `programs.<name>` (e.g. Steam) rather than `environment.systemPackages`, use that form
- If an application is a KDE/Plasma plugin or extension (e.g. a tiling script like Krohnkite), note that it may need to be installed via `environment.systemPackages` with the appropriate KDE package name, or via a Home Manager option
- If you cannot find a confident nixpkgs mapping, say so clearly rather than guessing

Apply the minimal diff to `modules/desktop/applications.nix` to make it match the spec. Do not remove comments or restructure the file beyond what is needed.

### Step 4 — Reconcile hardware
Compare `home-computer-hardware.txt` against the current GPU/CPU configuration in `modules/desktop/gpu.nix` and `hosts/home-computer/configuration.nix`.

Check for changes in:
- **GPU vendor/model** — update `services.xserver.videoDrivers`, `boot.initrd.kernelModules`, `hardware.graphics.extraPackages`, and `environment.sessionVariables` as appropriate for the GPU (AMD vs NVIDIA vs Intel)
- **CPU vendor** — update `hardware.cpu.amd.updateMicrocode` or `hardware.cpu.intel.updateMicrocode`
- **WiFi chipset** — update `boot.kernelModules` (WiFi driver module name) and note whether `hardware.enableRedistributableFirmware` is sufficient or a custom firmware package is needed
- **Ethernet only** — if hardware is ethernet-only, note that the `mt7921e` module can be removed

Apply changes only if the hardware has actually changed.

### Step 5 — Report
Print a clear summary:
- What packages were added / removed in applications.nix
- What hardware-related config changed (if any)
- Any items from the spec files that could not be automatically mapped (needs manual attention)
- Remind the user to run `nix flake check` then `sudo nixos-rebuild test --flake .#home-computer` to validate before switching

## Constraints
- Only modify `modules/desktop/applications.nix`, `modules/desktop/gpu.nix`, and `hosts/home-computer/configuration.nix`
- Do not touch home-server, vm-test, or any shared modules
- Do not restructure or reformat files beyond the minimal required changes
- `nixpkgs.config.allowUnfree = true` is already set — unfree packages like Chrome, Discord, and Android Studio are fine
