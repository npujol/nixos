{pkgs, ...}: {
  imports = [
    ./common.nix
  ];
  #--------------------------------------------------------------------------
  # Here are all the packages that should only be in the laptop configuration
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
    slack
  ];
  services.syncthing.enable = true; # Enable the syncthing service
  services.syncthing.tray.enable = true; # Enable the syncthing tray
}
