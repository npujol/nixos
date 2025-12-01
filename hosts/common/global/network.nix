{
  pkgs,
  lib,
  ...
}: {
  hardware.bluetooth.enable = true;

  services.tailscale = {
    openFirewall = true;
    enable = true;
    useRoutingFeatures = "client";
  };

  services.resolved.enable = true;
  networking = {
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
      dns = "systemd-resolved";
    };
    useDHCP = false;
    firewall = {
      enable = false;
      trustedInterfaces = ["tailscale0"];
    };
  };

  services.opensnitch = {
    enable = true;
    rules = {
      systemd-timesyncd = {
        name = "systemd-timesyncd";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "simple";
          sensitive = false;
          operand = "process.path";
          data = "${lib.getBin pkgs.systemd}/lib/systemd/systemd-timesyncd";
        };
      };
      systemd-resolved = {
        name = "systemd-resolved";
        enabled = true;
        action = "allow";
        duration = "always";
        operator = {
          type = "simple";
          sensitive = false;
          operand = "process.path";
          data = "${lib.getBin pkgs.systemd}/lib/systemd/systemd-resolved";
        };
      };
    };
  };
}
