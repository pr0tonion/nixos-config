{ config, pkgs, lib, ... }:

{
  # Home Manager configuration for admin user
  home.username = "admin";
  home.homeDirectory = "/home/admin";
  home.stateVersion = "24.05";

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  # Bash configuration
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

      # NixOS specific
      nrs = "sudo nixos-rebuild switch --flake .#home-server";
      nrt = "sudo nixos-rebuild test --flake .#home-server";
      nrb = "sudo nixos-rebuild boot --flake .#home-server";
      nfu = "nix flake update";

      # Service management
      jctl = "journalctl";
      sctl = "systemctl";
      uctl = "systemctl --user";

      # Common service checks
      check-plex = "systemctl status plex";
      check-transmission = "systemctl status transmission";
      check-sonarr = "systemctl status sonarr";
      check-radarr = "systemctl status radarr";
    };

    bashrcExtra = ''
      # Custom prompt
      PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

      # Better history handling
      shopt -s histappend
      PROMPT_COMMAND="history -a;$PROMPT_COMMAND"
    '';
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "Admin";
    userEmail = "admin@home-server.local"; # Change this
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # Neovim configuration
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # We'll fetch the config from GitHub
    extraConfig = ''
      " Configuration will be loaded from ~/.config/nvim
    '';
  };

  # Fetch Neovim config from GitHub
  home.activation.cloneNeovimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/.config/nvim" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/pr0tonion/My-Config.git "$HOME/.config/neovim-temp"
      $DRY_RUN_CMD mkdir -p "$HOME/.config"
      $DRY_RUN_CMD mv "$HOME/.config/neovim-temp/nvim" "$HOME/.config/nvim"
      $DRY_RUN_CMD rm -rf "$HOME/.config/neovim-temp"
      echo "Neovim config cloned from GitHub"
    else
      echo "Neovim config already exists, skipping clone"
    fi
  '';

  # SSH configuration
  programs.ssh = {
    enable = true;
    forwardAgent = false;
    serverAliveInterval = 60;
    serverAliveCountMax = 3;
  };

  # Starship prompt (optional, modern prompt)
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

  # Useful packages for admin user
  home.packages = with pkgs; [
    # System tools
    htop
    btop
    ncdu
    tree
    ripgrep
    fd
    jq

    # Network tools
    curl
    wget
    nmap
    iperf3

    # Media tools
    ffmpeg
    mediainfo

    # Development
    git
    vim
  ];

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
