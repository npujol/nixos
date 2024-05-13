{
  pkgs,
  # unstablePkgs,
  config,
  ...
}: {
  imports = [
    ./common.nix
    # ./features/x11.nix
    # ./features/hyprland.nix
    ./features/laptop.nix
    # ./features/games.nix
    # ./features/daw.nix
  ];

  home.packages = with pkgs; [
    pgcli
    pre-commit
    poetry
    # unstablePkgs.blender-hip
    # unstablePkgs.gamescope

    # unstablePkgs.godot_4
    # nix-ld
    # swaylock
    audacity
    ddcutil
    # anki
  ];
}
