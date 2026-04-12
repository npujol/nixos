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

  home = {
    username = "k8os";
    homeDirectory = "/home/k8os";
    stateVersion = "22.05";
    enableNixpkgsReleaseCheck = false;
  };

  nix = {
    package = pkgs.nix;
    settings = {
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
  };

  home.packages = [
    pkgs.alejandra
    pkgs.autossh
    pkgs.aria2
    pkgs.bc
    pkgs.bridge-utils
    pkgs.btop # Resource monitor
    pkgs.cachix
    pkgs.clinfo
    pkgs.devenv
    pkgs.delta # Git diff viewer
    pkgs.dmidecode
    pkgs.dnsmasq
    pkgs.docker
    pkgs.docker-compose
    pkgs.file
    pkgs.firefox
    pkgs.gcc
    pkgs.git
    pkgs.git-absorb
    pkgs.git-lfs
    pkgs.git-standup
    pkgs.jq # JSON processor
    pkgs.kubectl
    pkgs.kubectx
    pkgs.kubernetes-helm
    pkgs.kompose
    pkgs.lf # Terminal file manager
    pkgs.lm_sensors
    pkgs.lsof
    pkgs.ncdu # Disk usage analyzer
    pkgs.neovim
    pkgs.nix-du # Nix store disk usage
    pkgs.nix-update
    pkgs.nmap
    pkgs.openssh
    pkgs.p7zip
    pkgs.patool
    pkgs.pciutils
    pkgs.powertop
    pkgs.python312
    pkgs.python312Packages.ipython
    pkgs.ripgrep # Fast search tool
    pkgs.rsync
    pkgs.simple-http-server
    pkgs.sshuttle
    pkgs.talosctl
    pkgs.tmux # Terminal multiplexer
    pkgs.unrar
    pkgs.unzip
    pkgs.usbutils
    pkgs.util-linux
    pkgs.uv # Python package manager
    pkgs.virtiofsd
    pkgs.virt-manager
    pkgs.wget
    pkgs.zpaq
  ];

  programs = {
    home-manager.enable = true;
    fzf.enable = true;
    firefox.enable = true;
    git = {
      signing.key = "/home/k8os/.ssh/id_ed25519.pub";
    };
  };
}
