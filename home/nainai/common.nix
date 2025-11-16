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
    aider-chat
    alejandra
    anki
    aria2
    audacity
    autossh
    bash-language-server
    bc
    btop
    cachix
    calibre
    cheese
    clinfo
    croc
    ddcutil
    delta
    devenv
    dmidecode
    docker
    docker-compose
    docker-compose-language-service
    doggo
    file
    flameshot
    freefilesync
    gcc
    gh
    git
    git-absorb
    git-lfs
    git-standup
    gopls
    golangci-lint-langserver
    gparted
    htop
    hugo
    inputs.plasma-manager.packages.${pkgs.stdenv.hostPlatform.system}.rc2nix
    jq
    kubectl
    kubectx
    kubernetes-helm
    lf
    lm_sensors
    lsof
    lua-language-server
    markdown-oxide
    markdownlint-cli
    markdownlint-cli2
    myPkgs.wl_shimeji
    ncdu
    neovim
    nerd-fonts.symbols-only
    nil
    nmap
    nodejs_24
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    obsidian
    ollama
    opencommit
    openssh
    p7zip
    patool
    pciutils
    pgcli
    pipenv
    powertop
    pre-commit
    python311Packages.ipython
    python312
    rancher
    ripgrep
    rsync
    rustup
    simple-http-server
    sshuttle
    tdrop
    tinymist
    tree-sitter
    unrar
    unzip
    uv
    util-linux
    vscode
    wget
    wl-clipboard
    xclip
    xh
    zpaq
    (unstablePkgs.iosevka-bin.override {variant = "SGr-IosevkaTermSS07";})
    (unstablePkgs.ruff)
    (unstablePkgs.telegram-desktop)
    (unstablePkgs.typst)
    (unstablePkgs.wineWowPackages.staging)
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
