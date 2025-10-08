{
  description = "NixOS Home Server Configuration";

  inputs = {
    # Use latest stable NixOS
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    # Use unstable for newer packages when needed
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home Manager for user configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
  let
    system = "x86_64-linux";

    # Create unstable package set
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

    # Common arguments for all hosts
    commonArgs = {
      inherit system;
      specialArgs = {
        inherit inputs pkgs-unstable;
      };
    };
  in
  {
    # NixOS Configurations
    nixosConfigurations = {
      # Home Server Configuration
      home-server = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          # Hardware configuration
          ./hosts/home-server/hardware-configuration.nix

          # Base system configuration
          ./hosts/home-server/configuration.nix

          # Common modules
          ./modules/base.nix
          ./modules/networking.nix
          ./modules/users.nix

          # Service modules
          ./modules/services/plex.nix
          ./modules/services/media-automation.nix
          ./modules/services/torrent.nix
          ./modules/services/monitoring.nix
          ./modules/services/vpn.nix
          ./modules/services/dashboard.nix

          # Maintenance modules
          ./modules/maintenance/cleanup.nix

          # Home Manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.admin = import ./home/admin.nix;
          }
        ];
      };

      # Home Computer Configuration (skeleton for future use)
      home-computer = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          ./hosts/home-computer/configuration.nix
          ./modules/base.nix
          ./modules/networking.nix
          ./modules/users.nix
        ];
      };

      # VM Test Configuration (for testing before deploying to hardware)
      vm-test = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs pkgs-unstable; };
        modules = [
          # Hardware configuration
          ./hosts/vm-test/hardware-configuration.nix

          # VM-specific configuration
          ./hosts/vm-test/configuration.nix

          # Common modules
          ./modules/base.nix
          ./modules/networking.nix
          ./modules/users.nix

          # Service modules (same as home-server)
          ./modules/services/plex.nix
          ./modules/services/media-automation.nix
          ./modules/services/torrent.nix
          ./modules/services/monitoring.nix
          ./modules/services/vpn.nix
          ./modules/services/dashboard.nix

          # Maintenance modules
          ./modules/maintenance/cleanup.nix

          # Home Manager integration
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.admin = import ./home/admin.nix;
          }
        ];
      };
    };

    # ISO image for installation
    nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        {
          # Add git and other tools to the installer
          environment.systemPackages = with nixpkgs.legacyPackages.${system}; [
            git
            vim
            wget
            curl
          ];
        }
      ];
    };
  };
}
