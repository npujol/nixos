{...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/global
    ../common/users/k8os.nix
    ../common/features/docker.nix
  ];

  hardware.cpu.amd.updateMicrocode = true;

  networking.hostName = "k8os";

  programs.fish.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "altgr-intl";
  };
}
