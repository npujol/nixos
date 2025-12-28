{
  pkgs,
  myPkgs,
  ...
}: {
  imports = [
    ./common.nix
  ];
  #--------------------------------------------------------------------------
  # Here are all the packages that should only be in the desktop configuration
  #--------------------------------------------------------------------------
  home.packages = with pkgs; [
    cheese
    myPkgs.eden-emu
    pkgs.krita
  ];
}
