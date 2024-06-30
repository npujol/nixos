{pkgs, ...}: {
  imports = [
    ./common.nix
  ];
  #--------------------------------------------------------------------------
  # Here are all the packages that should only be in the desktop configuration
  #--------------------------------------------------------------------------
  home.packages = with pkgs; [
    pgcli
    pre-commit
    poetry
    audacity
    ddcutil
    flameshot
    anki
    obsidian
  ];
  services.syncthing.enable = true; # Enable the syncthing service
  services.syncthing.tray.enable = true; # Enable the syncthing tray
}
