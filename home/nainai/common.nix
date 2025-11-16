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
  ];

  home = {
    username = lib.mkDefault "nainai";
    homeDirectory = lib.mkDefault "/home/${config.home.username}";
    stateVersion = lib.mkDefault "22.05";
    enableNixpkgsReleaseCheck = false;
  };
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

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
    config.common.default = "*";
  };

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
    yt-dlp = {
      enable = true;
      settings = {
        cookies-from-browser = "firefox";
        downloader = "aria2c";
      };
    };
  };

  fonts.fontconfig.enable = true;

  gtk = {
    gtk2.enable = false;
    enable = true;
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    font = {
      package = pkgs.inter;
      name = "Inter";
    };
  };

  qt.enable = true;

  services.trayscale = {
    enable = true;
  };

  services.syncthing.enable = true; # Enable the syncthing service
  services.syncthing.tray.enable = true; # Enable the syncthing tray
  # Workaround to add a target in KDE
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = ["graphical-session-pre.target"];
    };
  };

  home.sessionVariables = {
    BROWSER = "firefox";
    TERMCMD = "kitty";
    EDITOR = "neovim";
    # Fix telegram input
    ALSOFT_DRIVERS = "pulse";
    # Disable qt decoration for telegram
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    NIXOS_OZONE_WL = 1;
  };

  #---------------------------------------------------------------------------
  # In this section we configure the user services, such as: mpris-proxy, etc.
  #---------------------------------------------------------------------------
  services = {
    ollama.enable = true;
  };

  # Force Rewrite
  manual.manpages.enable = false; # Doc framework is broken, so let's stop updating this
  xdg.configFile."mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/tg" = "telegram.desktop";
      # TODO: Update the default applications
      "inode/directory" = "dolphin.desktop";
      "text/x-python" = "code.desktop";
      "text/plain" = "code.desktop";
      "application/zip" = "xarchiver.desktop";
      "application/pdf" = "okular.desktop";
      "application/browser" = "firefox.desktop";
      "text/html" = "firefox.desktop";
    };
  };

  home.file."${config.xdg.configHome}/nvim/spell/de.utf-8.spl".source = builtins.fetchurl {
    url = "https://ftp.nluug.nl/pub/vim/runtime/spell/de.utf-8.spl";
    sha256 = "sha256:1ld3hgv1kpdrl4fjc1wwxgk4v74k8lmbkpi1x7dnr19rldz11ivk";
  };
}
