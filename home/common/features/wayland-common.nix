# Common wayland packages
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    wev
    wl-clipboard
    wdisplays
  ];
}