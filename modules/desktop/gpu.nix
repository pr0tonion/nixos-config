{ config, pkgs, lib, ... }:

{
  # Load amdgpu early so display works before login screen
  # BIOS: set "Primary Display" to PCIE to guarantee discrete GPU is always primary
  boot.initrd.kernelModules = [ "amdgpu" ];

  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for Steam 32-bit games
  };

  # AMD Ryzen microcode updates
  hardware.cpu.amd.updateMicrocode = true;

  # Hide the Raphael iGPU (1002:164e) from Vulkan so games can't pick it.
  # UE5 titles (Dragonwilds, Far Far West) were binding to the iGPU's 512 MB
  # VRAM instead of the RX 5700 XT, causing unplayable lag. The trailing "!"
  # makes RADV expose only the matched device.
  environment.sessionVariables = {
    MESA_VK_DEVICE_SELECT = "1002:731f!";
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };
}
