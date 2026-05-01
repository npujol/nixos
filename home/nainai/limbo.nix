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
    cheese
    myPkgs.eden-emu
    gimp
    krita
    # unstablePkgs.llama-cpp-vulkan
    pdftk
    sops
    sqlitebrowser
    thunar
    yazi

    openrgb
  ];
}
