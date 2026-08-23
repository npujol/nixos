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

  programs.thunderbird = {
    enable = true;
    profiles.nainai = {
      isDefault = true;
      settings = {
        "mail.root.dir-text" = "/home/nainai/Thunderbird/Mail/Local Folders";
      };
    };
  };
}
