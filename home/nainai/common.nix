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
    # Package Management & Utilities
    util-linux
    nix-update
    cachix
    patool
    opencommit

    # Python Packages
    python311Packages.ipython
    python312
    pipenv
    # python312Packages.gtts
    xclip

    # Fonts
    (unstablePkgs.iosevka-bin.override {variant = "SGr-IosevkaTermSS07";})
    nerd-fonts.symbols-only

    noto-fonts-color-emoji
    noto-fonts-cjk-sans
    noto-fonts

    # System Utilities
    pciutils
    unzip
    dmidecode
    bc
    jq
    usbutils
    wget
    nmap
    lm_sensors
    lsof
    file
    unrar
    aria2
    zpaq
    p7zip
    gparted
    htop
    btop
    lf
    ripgrep
    rsync
    clinfo
    powertop
    ncdu
    freefilesync
    unstablePkgs.wineWowPackages.staging
    aider-chat
    nix-du

    # language-servers
    markdownlint-cli
    marksman
    bash-language-server
    docker-compose-language-service
    golangci-lint-langserver
    gopls
    markdown-oxide
    tinymist

    # Development Tools
    lua-language-server
    gcc
    rustup
    simple-http-server
    delta
    gh
    git
    git-standup
    git-absorb
    git-lfs
    vscode
    (unstablePkgs.ruff)
    kubectl
    kubectx
    # k3d
    neovim
    rancher
    kubernetes-helm
    devenv
    uv
    # lens
    kompose
    markdownlint-cli2

    # Web Browsers

    # brave
    # Networking Tools
    sshuttle
    autossh
    openssh
    docker
    docker-compose
    ollama

    # Media & Graphics
    # TODO reenable?
    # darktable
    # gimp
    # inkscape
    # ffmpeg-full
    # graphviz

    # calibre
    # glslviewer
    # ollama-rocm
    # blender
    # freecad
    # godot
    # libreoffice
    # zoom-us

    # Terminal & Shell
    # kitty

    # Virtualization &
    # steam
    # steam-run
    # android-tools

    # Other Applications
    # easyeffects

    (unstablePkgs.typst)
    nil
    doggo
    anki
    xh
    tdrop
    (unstablePkgs.telegram-desktop)
    alejandra
    # emanote
    keepassxc
    croc
    # krita
    tree-sitter
    nodejs_24
    hugo
    inputs.plasma-manager.packages.${pkgs.system}.rc2nix
    wl-clipboard
    myPkgs.wl_shimeji
    # (unstablePkgs.llama-cpp.override {vulkanSupport = true;})
  ];

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
    config.common.default = "*";
  };

  programs = {
    home-manager.enable = true;

    fzf.enable = true;

    firefox = {
      enable = true;
    };

    yt-dlp = {
      enable = true;
      settings = {
        # TODO: Review why the cookies are not working
        # cookies-from-browser = "firefox";
        downloader = "aria2c";
      };
    };

    bat = {
      enable = true;
    };
    direnv.enable = true;
    direnv.nix-direnv.enable = true;

    git = {
      signing.key = "/home/nainai/.ssh/id_ed25519.pub";
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
    # mpris-proxy.enable = true;
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

  #---------------------
  # Clean up nix cache
  #---------------------
  # nix.gc.automatic = true;
}
