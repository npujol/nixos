{
  unstablePkgs,
  lib,
  pkgs,
  config,
  inputs,
  myPkgs,
  ...
}: {
  imports = [
    ../../shared/nix.nix
    ../common/features/cmds.nix
    ../common/features/mpv.nix
    ../common/features/git.nix
    ../common/features/kitty.nix
    ../common/features/fish.nix
    ../common/features/kde.nix
    ../common/features/syncthing.nix
    ../common/features/gtk.nix
    ../common/features/ytdlp.nix
    ../common/features/session-variables.nix
    ../common/features/default-apps.nix
  ];

  #--------------------------------------------------------------------
  #-- Base Home Manager Configuration
  #--------------------------------------------------------------------
  home = {
    username = lib.mkDefault "nainai";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "22.05";
    enableNixpkgsReleaseCheck = false;
  };

  #--------------------------------------------------------------------
  #-- Nix Configuration
  #--------------------------------------------------------------------
  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };

  #--------------------------------------------------------------------
  #-- Packages
  # Grouped by category for better readability.
  #--------------------------------------------------------------------
  home.packages = with pkgs;
  with builtins;
  with lib; [
    ##### System Utilities / CLI Tools #####
    aria2
    autossh
    bc
    btop
    cachix
    clinfo
    ddcutil
    dmidecode
    doggo
    file
    gcc
    htop
    lm_sensors
    lsof
    ncdu
    nmap
    patool
    pciutils
    powertop
    ripgrep
    rsync
    simple-http-server
    tdrop
    unrar
    unzip
    util-linux
    wget
    xh
    zpaq

    ##### Development Tools #####
    bash-language-server
    delta
    docker
    docker-compose
    docker-compose-language-service
    gh
    git
    git-absorb
    git-lfs
    git-standup
    gopls
    golangci-lint-langserver
    jq
    lua-language-server
    nil
    nodejs_24
    opencommit
    pipenv
    pre-commit
    python311Packages.ipython
    python312
    rustup
    tree-sitter
    uv

    ##### DevOps / Cloud / Kubernetes #####
    croc
    devenv
    kubectl
    kubectx
    kubernetes-helm
    ollama
    openssh
    rancher
    sshuttle

    ##### Editor & Writing / Markdown #####
    markdown-oxide
    markdownlint-cli
    markdownlint-cli2
    neovim
    obsidian
    vscode

    ##### Fonts #####
    nerd-fonts.symbols-only
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    (unstablePkgs.iosevka-bin.override {variant = "SGr-IosevkaTermSS07";})

    ##### Multimedia / GUI Tools #####
    audacity
    cheese
    flameshot
    freefilesync
    gparted
    p7zip
    tinymist

    ##### Apps / Productivity #####
    aider-chat
    alejandra
    anki
    calibre
    hugo
    myPkgs.wl_shimeji
    wl-clipboard
    xclip
    android-tools

    ##### Plasma Manager #####
    inputs.plasma-manager.packages.${pkgs.stdenv.hostPlatform.system}.rc2nix

    ##### Unstable Packages #####
    (unstablePkgs.ruff)
    (unstablePkgs.telegram-desktop)
    (unstablePkgs.typst)
    (unstablePkgs.wineWowPackages.staging)
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];
  #--------------------------------------------------------------------
  #-- Programs & Services Configuration
  #--------------------------------------------------------------------
  programs = {
    home-manager.enable = true;
    fzf.enable = true;
    firefox.enable = true;
    bat.enable = true;
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
    git = {
      signing.key = "/home/nainai/.ssh/id_ed25519.pub";
    };
  };

  fonts.fontconfig.enable = true;
  qt.enable = true;

  #---------------------------------------------------------------------------
  # In this section we configure the user services, such as: mpris-proxy, etc.
  #---------------------------------------------------------------------------
  services = {
    ollama.enable = true;
  };

  home.file."${config.xdg.configHome}/nvim/spell/de.utf-8.spl".source = builtins.fetchurl {
    url = "https://ftp.nluug.nl/pub/vim/runtime/spell/de.utf-8.spl";
    sha256 = "sha256:1ld3hgv1kpdrl4fjc1wwxgk4v74k8lmbkpi1x7dnr19rldz11ivk";
  };
}
