{pkgs, ...}: {
  imports = [
    ./common.nix
    ./pi.nix
  ];
  #--------------------------------------------------------------------------
  # Here are all the packages that should only be in the laptop configuration
  #--------------------------------------------------------------------------
  home.packages = with pkgs; [
    gimp
    nix-tree
    zoom-us
    sops
    thunderbird
  ];
  # Force Rewrite
  manual.manpages.enable = false; # Doc framework is broken, so let's stop updating this
  services.opensnitch-ui.enable = true;
}
