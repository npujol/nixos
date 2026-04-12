{pkgs, ...}: {
  home.packages = with pkgs; [
    wev
    wl-clipboard
    wdisplays
  ];
}

