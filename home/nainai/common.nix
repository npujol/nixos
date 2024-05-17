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
    lf
    fzf
    ripgrep
    rsync
    clinfo
    powertop

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
    docker-compose

    # Media & Graphics
    darktable
    gimp
    inkscape
    ffmpeg-full
    graphviz

    # Terminal & Shell
    kitty
    xorg.xkill
    thefuck

    # Virtualization & Emulation
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
      # "inode/directory" = "thunar.desktop";
      # "inode/directory" = "pcmanfm.desktop";
      # "text/x-python" = "code.desktop";
      # "text/plain" = "code.desktop";
      # "application/zip" = "xarchiver.desktop";
      # "application/pdf" = "org.pwmt.zathura.desktop";
      # "application/epub+zip" = "org.pwmt.zathura.desktop.desktop";
      # # "image/*" = "com.github.weclaw1.ImageRoll.desktop";
    };
  };

  #---------------------
  # Clean up nix cache
  #---------------------
  systemd.user.services = {
    shit_collector = {
      Unit = {
        Description = "Remove nix shit";
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 10d";
      };
      Install.WantedBy = ["default.target"];
    };
  };
  systemd.user.timers = {
    shit_collector_chron = {
      Unit.Description = "Remove nix shit";
      Timer = {
        Unit = "shit_collector";
        OnBootSec = "15m";
        OnUnitActiveSec = "1w";
      };
      Install.WantedBy = ["timers.target"];
    };
  };
}
