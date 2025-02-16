{pkgs, ...}: {
  # Example: https://github.com/nix-community/plasma-manager/blob/trunk/examples/home.nix
  programs.plasma = {
    enable = true;

    #
    # Some high-level settings:
    #
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      iconTheme = "Breeze-Dark";
      wallpaper = "${./files/desktop.jpg}";
    };
  };
}
