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
    ../common/features/syncthing.nix
    ../common/features/gtk.nix
    ../common/features/ytdlp.nix
    ../common/features/session-variables.nix
    ../common/features/default-apps.nix
    ../common/features/neovim.nix
    ../common/features/hyprland.nix
    ../common/features/noctalia.nix
  ];

  home = {
    username = lib.mkDefault "nainai";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "26.05";
    enableNixpkgsReleaseCheck = false;
  };

  my.neovim.enable = true;

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };

  home.packages = with pkgs;
  with builtins;
  with lib; [
    alejandra
    android-tools
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
    devenv
    delta
    dmidecode
    doggo
    docker
    docker-compose
    docker-compose-language-service
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
    hugo
    htop
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
    jq
    kubectl
    kubectx
    kubernetes-helm
    lm_sensors
    lsof
    lua-language-server
    markdownlint-cli
    markdownlint-cli2
    markdown-oxide
    myPkgs.wl_shimeji
    ncdu
    nerd-fonts.symbols-only
    nil
    nmap
    nodejs_24
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    obsidian
    opencommit
    p7zip
    patool
    pciutils
    pipenv
    powertop
    pre-commit
    python312
    rancher
    ripgrep
    rsync
    rustup
    simple-http-server
    sshuttle
    steam-run
    tdrop
    tinymist
    tree-sitter
    unrar
    unzip
    util-linux
    uv
    vscode
    wget
    wl-clipboard
    xclip
    xh
    zen-browser
    zpaq

    (unstablePkgs.iosevka-bin.override {variant = "SGr-IosevkaTermSS07";})
    (unstablePkgs.ruff)
    (unstablePkgs.telegram-desktop)
    (unstablePkgs.typst)
    (unstablePkgs.wineWow64Packages.staging)

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
    ollama = {
      enable = true;
      package = unstablePkgs.ollama-vulkan;
    };
  };
}
