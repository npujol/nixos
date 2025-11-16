{pkgs, ...}: {
  imports = [
    ../../shared/nix.nix
    ../common/features/cmds.nix
    ../common/features/git.nix
    ../common/features/fish.nix
    ../common/features/kitty.nix
    ../common/features/kde.nix
    ../common/features/syncthing.nix
    ../common/features/session-variables.nix
  ];

  #--------------------------------------------------------------------
  #-- Base Home Manager Configuration
  #--------------------------------------------------------------------
  home = {
    username = "k8os";
    homeDirectory = "/home/k8os";
    stateVersion = "22.05";
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
  home.packages = [
    # --- Core System & CLI Utilities ---
    pkgs.util-linux
    pkgs.btop # Resource monitor
    pkgs.ncdu # Disk usage analyzer
    pkgs.nix-du # Nix store disk usage
    pkgs.lf # Terminal file manager
    pkgs.ripgrep # Fast search tool
    pkgs.jq # JSON processor
    pkgs.pciutils
    pkgs.usbutils
    pkgs.lm_sensors
    pkgs.lsof
    pkgs.file
    pkgs.rsync
    pkgs.tmux # Terminal multiplexer

    # --- Archiving & Compression ---
    pkgs.unzip
    pkgs.unrar
    pkgs.p7zip
    pkgs.patool
    pkgs.zpaq
    pkgs.aria2

    # --- Development & Version Control ---
    pkgs.git
    pkgs.delta # Git diff viewer
    pkgs.git-standup
    pkgs.git-absorb
    pkgs.git-lfs
    pkgs.gcc
    pkgs.neovim
    pkgs.devenv

    # --- Python ---
    pkgs.python312
    pkgs.python312Packages.ipython
    pkgs.uv # Python package manager

    # --- Containers & Kubernetes ---
    pkgs.docker
    pkgs.docker-compose
    pkgs.kubectl
    pkgs.kubectx
    pkgs.kubernetes-helm
    pkgs.kompose
    pkgs.talosctl

    # --- Networking ---
    pkgs.nmap
    pkgs.wget
    pkgs.sshuttle
    pkgs.autossh
    pkgs.openssh
    pkgs.simple-http-server
    pkgs.dnsmasq
    pkgs. bridge-utils

    # --- Nix Ecosystem ---
    pkgs.nix-update
    pkgs.cachix
    pkgs.alejandra

    # --- Virtualization ---
    pkgs.virt-manager
    pkgs.talosctl
    pkgs.virtiofsd

    # --- Misc Hardware/System ---
    pkgs.dmidecode
    pkgs.clinfo
    pkgs.powertop
    pkgs.bc
    pkgs.firefox
  ];

  #--------------------------------------------------------------------
  #-- Programs & Services Configuration
  #--------------------------------------------------------------------
  programs = {
    home-manager.enable = true;
    fzf.enable = true;
    firefox.enable = true;
    git = {
      signing.key = "/home/k8os/.ssh/id_ed25519.pub";
    };
  };
}
