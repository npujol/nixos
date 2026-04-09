{
  pkgs,
  myPkgs,
  ...
}: {
  imports = [
    ./common.nix
    ./pi.nix
  ];
  #--------------------------------------------------------------------------
  # Here are all the packages that should only be in the desktop configuration
  #--------------------------------------------------------------------------
  home.packages = with pkgs; [
    cheese
    myPkgs.eden-emu
    krita
    pdftk
    sqlitebrowser
    gimp
    sops
    llama-cpp-vulkan
  ];
}
