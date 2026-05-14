# This file (and the global directory) holds config that i use on all hosts
{
  pkgs,
  inputs,
  lib,
  config,
  ...
}: {
  imports = [
    ./audio.nix
    ./boot.nix
    ./games.nix
    ./gl.nix
    ./locale.nix
    ./network.nix
    ./nfs.nix
    ./nix.nix
    ./services.nix
    ./security.nix
  ];
  environment = {
    loginShellInit = ''
      # Activate home-manager environment, if not already
      [ -d "$HOME/.nix-profile" ] || /nix/var/nix/profiles/per-user/$USER/home-manager/activate &> /dev/null
    '';

    enableAllTerminfo = false;
  };

  system.stateVersion = "23.11";

  programs.fuse.userAllowOther = true;
  programs.dconf.enable = true;
  programs.fish.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;
  # services.desktopManager.plasma6.enable = false;
  # programs.hyprland.enable = true;

  services.greetd = {
    enable = true;
    settings = let
      command = "start-hyprland";
      user = "nainai";
    in {
      default_session = {
        command = "${lib.getExe pkgs.tuigreet} --time --cmd ${command} --user-menu --remember";
        user = "greeter";
      };

      initial_session = {
        command = command;
        user = user;
      };
    };
  };
  environment.systemPackages = with pkgs; [
    vim
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
  ];
}
