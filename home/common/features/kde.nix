{...}: {
  # Example: https://github.com/nix-community/plasma-manager/blob/trunk/examples/home.nix
  programs.plasma = {
    enable = false;
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

    input.keyboard.layouts = [
      {
        displayName = "usi";
        layout = "us";
        variant = "altgr-intl";
      }
    ];
    shortcuts = {
      "services/kitty-toggle.desktop" = {
        _launch = "F12";
      };
    };
  };

  xdg.desktopEntries = {
    kitty-toggle = {
      name = "Kitty toggle";
      genericName = "kitty toggle";
      exec = "kitten quick-access-terminal";
      terminal = false;
    };
  };
}
