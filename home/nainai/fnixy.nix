{pkgs, ...}: {
  imports = [
    ./common.nix
    ./pi.nix
  ];
  home.packages = with pkgs; [
    gimp
    nix-tree
    sops
    thunderbird
    zoom-us
  ];
  # Force Rewrite
  manual.manpages.enable = false; # Doc framework is broken, so let's stop updating this
  services.opensnitch-ui.enable = true;
}
