{...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/global
    ../common/users/nainai.nix
    ../common/features/docker.nix
  ];

  hardware.cpu.amd.updateMicrocode = true;

  networking.hostName = "nixos";

  programs.fish.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma5.enable = true;
  
  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "altgr-intl";
  };
}
