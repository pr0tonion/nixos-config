{ config, pkgs, lib, ... }:

{
  # Home Manager config for the admin user on home-computer (desktop).
  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyControl = [ "ignoredups" "ignorespace" ];
    historySize = 10000;

    shellAliases = {
      ll = "ls -alh";
      la = "ls -A";
      l = "ls -CF";
      ".." = "cd ..";
      "..." = "cd ../..";

      # NixOS rebuild (home-computer)
      nrs = "sudo nixos-rebuild switch --flake .#home-computer";
      nrt = "sudo nixos-rebuild test --flake .#home-computer";
      nrb = "sudo nixos-rebuild boot --flake .#home-computer";
      nfu = "nix flake update";

      # Service helpers
      jctl = "journalctl";
      sctl = "systemctl";
      uctl = "systemctl --user";
    };

    bashrcExtra = ''
      shopt -s histappend
      PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
    '';
  };

  programs.git = {
    enable = true;
    userName = "Marcus Pedersen";
    userEmail = "marcus.pedersen95@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  # Pull personal Neovim config on first activation.
  home.activation.cloneNeovimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/.config/nvim" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/pr0tonion/My-Config.git "$HOME/.config/neovim-temp"
      $DRY_RUN_CMD mkdir -p "$HOME/.config"
      $DRY_RUN_CMD mv "$HOME/.config/neovim-temp/nvim" "$HOME/.config/nvim"
      $DRY_RUN_CMD rm -rf "$HOME/.config/neovim-temp"
    fi
  '';

  programs.ssh = {
    enable = true;
    forwardAgent = false;
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };
    };
  };

  # Per-project shell environments
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
  };

  home.packages = with pkgs; [
    # CLI essentials
    htop
    btop
    ncdu
    tree
    ripgrep
    fd
    fzf
    bat
    eza
    zoxide
    jq
    gh

    # Network
    curl
    wget
    nmap
    iperf3

    # Media
    ffmpeg
    mediainfo

    # Nix tooling (LSP + formatter for VSCode/Neovim)
    nil
    nixpkgs-fmt
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
