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
    # unstablePkgs.llama-cpp-vulkan
    pdftk
    sqlitebrowser
    yazi
    openrgb
    steam
  ];
}
