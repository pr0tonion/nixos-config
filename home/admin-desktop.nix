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
      deploy-nix = "sudo nixos-rebuild switch --flake /etc/nixos-config#home-computer";
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

  home.activation.linkNixosConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "$HOME/code"
    if [ ! -e "$HOME/code/nixos-config" ]; then
      $DRY_RUN_CMD ln -s /etc/nixos-config "$HOME/code/nixos-config"
    fi
  '';

  # Pull personal Neovim config on first activation.
  home.activation.cloneNeovimConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -d "$HOME/code/dotfiles" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/pr0tonion/dotfiles.git "$HOME/code/dotfiles"
    fi
    if [ ! -e "$HOME/.config/nvim" ]; then
      $DRY_RUN_CMD mkdir -p "$HOME/.config"
      $DRY_RUN_CMD ln -s "$HOME/code/dotfiles/nvim" "$HOME/.config/nvim"
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

    # Wayland clipboard provider for Neovim
    wl-clipboard
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  programs.plasma.configFile."kaccessrc"."ScreenReader"."Enabled".value = false;

  programs.plasma.configFile."kwinrc"."Desktops"."Number".value = 4;
  programs.plasma.configFile."kwinrc"."Desktops"."Id_1".value = "f58341d4-cbac-4774-8425-d5be1a398d4b";
  programs.plasma.configFile."kwinrc"."Desktops"."Id_2".value = "3723bcd7-b8c5-494a-9c85-4189084eb7bb";
  programs.plasma.configFile."kwinrc"."Desktops"."Id_3".value = "56e530b9-722a-4f99-8d94-352c737b142a";
  programs.plasma.configFile."kwinrc"."Desktops"."Id_4".value = "09a65991-e104-41fb-a2e1-b445b87876b9";
  programs.plasma.configFile."kcminputrc"."Keyboard"."NumLock".value = 0;

  # programs.plasma.shortcuts doesn't reliably write to kglobalshortcutsrc,
  # so we use kwriteconfig6 directly in an activation script.
  home.activation.kdeShortcuts = lib.hm.dag.entryAfter ["writeBoundary"] ''
    kwrite="${pkgs.kdePackages.kconfig}/bin/kwriteconfig6"

    # Lock Session: Meta+Home only (drop default Meta+L as current binding)
    $DRY_RUN_CMD $kwrite --file kglobalshortcutsrc \
      --group ksmserver --key "Lock Session" \
      "Meta+Home,$(printf 'Screensaver\tMeta+L'),Lock Session"

    # Free Meta+1-4 from plasmashell so kwin can claim them
    for i in 1 2 3 4; do
      $DRY_RUN_CMD $kwrite --file kglobalshortcutsrc \
        --group plasmashell \
        --key "activate task manager entry $i" \
        "none,Meta+$i,Activate Task Manager Entry $i"
    done

    # Krohnkite: Focus Right
    $DRY_RUN_CMD $kwrite --file kglobalshortcutsrc \
      --group kwin --key "KrohnkiteFocusRight" \
      'Meta+L,none,Krohnkite: Focus Right'

    # Assign Meta+1-4 to kwin desktop switching
    for i in 1 2 3 4; do
      $DRY_RUN_CMD $kwrite --file kglobalshortcutsrc \
        --group kwin \
        --key "Switch to Desktop $i" \
        "Meta+$i,Ctrl+F$i,Switch to Desktop $i"
    done

    # Move active window to desktop 1-4
    for i in 1 2 3 4; do
      $DRY_RUN_CMD $kwrite --file kglobalshortcutsrc \
        --group kwin \
        --key "Window to Desktop $i" \
        "Meta+Alt+$i,none,Window to Desktop $i"
    done
  '';
}
