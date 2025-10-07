# VM Hardware Configuration Template
# This will be replaced when you run nixos-generate-config in the VM

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  # VM-friendly settings
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "virtio_blk" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Filesystem configuration (will be generated during install)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # For VM testing, you can create a smaller media partition
  # or use a shared folder from host
  fileSystems."/srv/media" = {
    device = "/dev/disk/by-label/media";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  swapDevices = [ ];

  # VM doesn't need these optimizations
  hardware.cpu.intel.updateMicrocode = lib.mkDefault false;

  # Disable GPU-related settings for VM
  hardware.opengl.enable = lib.mkDefault false;
}
