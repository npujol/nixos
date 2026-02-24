{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./features/restic.nix
    ./features/immich.nix
    ./features/calibre.nix
    ./features/memos.nix
    ./features/paperless.nix
    ./features/headscale.nix
    ./features/languagetool.nix
    ./hardware-configuration.nix
    ../common/global
    ../common/users/k8os.nix
    ../common/features/docker.nix
    ../common/features/talos-homelab.nix
    ../common/features/talos-mvs.nix
  ];

  networking.hostName = "k8os";

  boot.extraModulePackages = with config.boot.kernelPackages; [
    zenpower
  ];
  programs.nh.flake = "/home/k8os/nixos";

  networking.firewall.enable = false;
  # networking.firewall.allowedTCPPorts = [80];

  services.displayManager.sddm.enable = lib.mkForce false;
  services.desktopManager.plasma6.enable = lib.mkForce false;

  services.tuned.enable = true;
  services.power-profiles-daemon.enable = false;

  hardware.graphics = {
    enable = true;
  };
  hardware.nvidia = {
    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.xserver.videoDrivers = ["nvidia"];
  # hardware.graphics.enable = true;
  boot.blacklistedKernelModules = ["nouveau"];
}
