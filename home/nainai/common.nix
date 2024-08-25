{
  unstablePkgs,
  lib,
  pkgs,
  config,
  ...
}: {
  imports = [
    ../../shared/nix.nix
    ./features/cmds.nix
    ./features/mpv.nix
    ./features/git.nix
    ./features/kitty.nix
    ./features/fish.nix
    ./features/kde.nix
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
      experimental-features = ["nix-command" "flakes" "repl-flake"];
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

    # Python Packages
    python311Packages.ipython
    python312
    pipenv

    # Fonts
    (unstablePkgs.iosevka-bin.override {variant = "SGr-IosevkaTermSS07";})
    (unstablePkgs.nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
    noto-fonts-emoji
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


    # Development Tools
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

    # Web Browsers
    brave

    # Networking Tools
    sshuttle
    autossh
    openssh
    docker
    docker-compose

    # Media & Graphics
    darktable
    gimp
    inkscape
    ffmpeg-full
    graphviz

    # Terminal & Shell
    # kitty
    xorg.xkill
    thefuck

    # Virtualization & 
    steam
    steam-run
    android-tools

    # Other Applications
    easyeffects
    ollama
    (unstablePkgs.typst)
    nil
    doggo
    anki
    xh
    tdrop
    (unstablePkgs.tdesktop)
    alejandra
    emanote
    
  ];

  programs = {
    home-manager.enable = true;

    fzf.enable = true;

    firefox = {
      enable = true;
    };

    yt-dlp = {
      enable = true;
      settings = {
        cookies-from-browser = "firefox";
        downloader = "aria2c";
      };
    };

    bat = {
      enable = true;
    };
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
  };

  fonts.fontconfig.enable = true;

  gtk = {
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

  home.sessionVariables = {
    BROWSER = "brave";
    TERMCMD = "kitty";
    EDITOR = "code";
    # Fix telegram input
    ALSOFT_DRIVERS = "pulse";
    # Disable qt decoration for telegram
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
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
      "application/browser" = "brave.desktop";
    };
  };

#---------------------
# Clean up nix cache
#---------------------
  nix.gc.automatic = true;
}
