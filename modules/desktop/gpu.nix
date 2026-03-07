{ config, pkgs, lib, ... }:

{
  # Load amdgpu early so display works before login screen
  # BIOS: set "Primary Display" to PCIE to guarantee discrete GPU is always primary
  boot.initrd.kernelModules = [ "amdgpu" ];

  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for Steam 32-bit games
    extraPackages = with pkgs; [
      amdvlk # Additional Vulkan ICD alongside Mesa RADV
    ];
  };

  # AMD Ryzen microcode updates
  hardware.cpu.amd.updateMicrocode = true;

  # Prefer Mesa RADV over amdvlk for gaming (better compatibility and performance)
  # Force VA-API and VDPAU to the discrete GPU
  environment.sessionVariables = {
    AMD_VULKAN_ICD = "RADV";
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };
}
