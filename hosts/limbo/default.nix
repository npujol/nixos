{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ../common/global
    ../common/users/nainai.nix
    ../common/features/docker.nix
  ];

  networking.hostName = "limbo";
  networking.firewall.enable = false;

  programs.nh.flake = "/home/nainai/projects/nixos";

  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };

  systemd.services.rgb-sleep-wake = {
    description = "Disable RGB on sleep, restart on wake";
    wantedBy = ["sleep.target" "suspend.target"];
    after = ["sleep.target" "suspend.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.openrgb}/bin/openrgb --off";
      RemainAfterExit = true;
    };
  };

  systemd.services.rgb-wake = {
    description = "Restart RGB on wake";
    wantedBy = ["suspend.target"];
    after = ["suspend.target" "sleep.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.openrgb}/bin/openrgb --preset default";
      RemainAfterExit = true;
    };
  };
}
