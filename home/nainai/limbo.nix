{
  pkgs,
  myPkgs,
  ...
}: {
  imports = [
    ./common.nix
    ./pi.nix
  ];
  home.packages = with pkgs; [
    myPkgs.eden-emu
    krita
    pdftk
    sqlitebrowser
    yazi
    openrgb
    steam
  ];
}
