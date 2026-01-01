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
    # hotkeys.commands = {
    #   "kitty-toggle" = {
    #     command = "kitten quick-access-terminal";
    #     key = "F12";
    #     name = "kitty-toggle";
    #   };
    # };
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

  xdg.portal = {
    enable = true;
    extraPortals = [pkgs.kdePackages.xdg-desktop-portal-kde];
    config.common.default = "*";
  };
}
