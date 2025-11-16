# This file (and the global directory) holds config that i use on all hosts
{
  pkgs,
  lib,
  inputs,
  outputs,
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

    # Add terminfo files
    enableAllTerminfo = true;
  };

  system.stateVersion = "23.11";

  programs.fuse.userAllowOther = true;
  programs.dconf.enable = true;
  programs.fish.enable = true;
  programs.adb.enable = true;

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;

  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  environment.systemPackages = with pkgs; [
    vim
  ];
}
