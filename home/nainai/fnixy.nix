{pkgs, ...}: {
  imports = [
    ./common.nix
    ./pi.nix
  ];
  home.packages = with pkgs; [
    nix-tree
    zoom-us
    steam
  ];
  manual.manpages.enable = false; # Doc framework is broken, so let's stop updating this
  services.opensnitch-ui.enable = true;

  programs.thunderbird = {
    enable = true;
    profiles.nainai.isDefault = true;
  };
}
