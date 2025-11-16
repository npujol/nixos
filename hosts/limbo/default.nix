{...}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ../common/global
    ../common/users/nainai.nix
    ../common/features/docker.nix
  ];

  networking.hostName = "limbo";
  programs.nh.flake = "/home/nainai/projects/nixos";

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
}
