{...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/global
    ../common/users/nainai.nix
    ../common/features/docker.nix
    ../common/features/opensnitch.nix
  ];

  networking.hostName = "fnixy";
  networking.firewall.enable = false;
  programs.nh.flake = "/home/nainai/projects/nix-config";
}
