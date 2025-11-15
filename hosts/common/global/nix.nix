{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [../../../shared/nix.nix];
  nix = {
    settings = {
      trusted-users = ["root" "@wheel"];
      auto-optimise-store = lib.mkDefault true;
      experimental-features = ["nix-command" "flakes"];
      warn-dirty = false;
    };
    # gc = {
    #
    #   automatic = true;
    #   dates = "weekly";
    # };
    # Add each flake input as a registry
    # To make nix3 commands consistent with the flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

    # Map registries to channels
    # Very useful when using legacy commands
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };
}
