{pkgs, ...}: {
  imports = [
    ./common.nix
    ./pi.nix
  ];
  home.packages = with pkgs; [
    nix-tree
    thunderbird
    zoom-us
    steam
  ];
  # Force Rewrite
  manual.manpages.enable = false; # Doc framework is broken, so let's stop updating this
  services.opensnitch-ui.enable = true;
}
