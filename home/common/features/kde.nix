{pkgs, ...}: {
  # Example: https://github.com/nix-community/plasma-manager/blob/trunk/examples/home.nix
  programs.plasma = {
    enable = true;
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      iconTheme = "Breeze-Dark";
      wallpaper = "${./files/desktop.jpg}";
    };
    panels = [
      {
        location = "right";
        hiding = "autohide";
      }
    ];
    hotkeys.commands = {
      "kitty-toggle" = {
        command = "kitten quick-access-terminal";
        key = "F12";
        comment = "kitty kitty-toggle";
      };
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
    config.common.default = "*";
  };
}
