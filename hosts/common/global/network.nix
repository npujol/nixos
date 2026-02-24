{...}: {
  hardware.bluetooth.enable = true;

  services.tailscale = {
    openFirewall = true;
    enable = true;
    useRoutingFeatures = "both";
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
    networkmanager.wifi.powersave = false;
  };
}
