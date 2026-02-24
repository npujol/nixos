{pkgs, ...}: {
  imports = [
    ./common.nix
  ];
  #--------------------------------------------------------------------------
  # Here are all the packages that should only be in the laptop configuration
  #--------------------------------------------------------------------------
  home.packages = with pkgs; [
    gimp
    nix-tree
    megasync
    zoom-us
  ];
  # Force Rewrite
  manual.manpages.enable = false; # Doc framework is broken, so let's stop updating this
  services.opensnitch-ui.enable = true;
}
