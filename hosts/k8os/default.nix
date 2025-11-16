{
  config,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common/global
    ../common/users/k8os.nix
    ../common/features/docker.nix
    ../common/features/talos-homelab.nix
    ../common/features/talos-mvs.nix
  ];

  networking.hostName = "k8os";

  boot.extraModulePackages = with config.boot.kernelPackages; [
    zenpower
  ];
  programs.nh.flake = "/home/k8os/nixos";

  users.users.immich.extraGroups = [
    "video"
    "render"
  ];

  networking.firewall.allowedTCPPorts = [80];

  services.displayManager.sddm.enable = lib.mkForce false;
  services.desktopManager.plasma6.enable = lib.mkForce false;

  services.tuned.enable = true;
  services.power-profiles-daemon.enable = false;

  services.immich.enable = true;
  services.immich.port = 2283;

  services.nginx.enable = true;
  services.nginx.virtualHosts."k8os" = {
    default = true;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };
}
