{pkgs, ...}: {
  # Example: https://github.com/nix-community/plasma-manager/blob/trunk/examples/home.nix
  programs.plasma = {
    enable = true;

    #
    # Some high-level settings:
    #
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
      # cursor = {
      #   theme = "Bibata-Modern-Ice";
      #   size = 32;
      # };
      iconTheme = "Breeze-Dark";
      wallpaper = "${./files/desktop.jpg}";
    };

    hotkeys.commands."launch-kitty" = {
      name = "Launch Kitty";
      key = "F12";
      command = "tdrop -ma -w -4 -h 80%  kitty -o hide_window_decorations=yes -o background_opacity=0.8";
    };
  };
}
