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

    hotkeys.commands."launch-kitty" = {
      name = "Launch Kitty";
      key = "F12";
      command = "tdrop -mt -w 100% -h 80%  kitty -o hide_window_decorations=yes -o background_opacity=0.8";
    };
  };
}
