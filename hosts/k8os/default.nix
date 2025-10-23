{config, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/global
    ../common/users/k8os.nix
    ../common/features/docker.nix
    ../common/features/talos-homelab.nix
    ../common/features/talos-mvs.nix
  ];

  hardware.cpu.amd.updateMicrocode = true;

  networking.hostName = "k8os";

  # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  # hardware.nvidia.open = true;
  # services.xserver.videoDrivers = ["nvidia"];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    zenpower
  ];
  programs.fish.enable = true;

  # services.tuned.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "altgr-intl";
  };
}
