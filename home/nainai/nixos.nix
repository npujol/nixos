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
  ];
}
