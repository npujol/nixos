# This file (and the global directory) holds config that i use on all hosts
{pkgs, ...}: {
  services = {
    fstrim.enable = true;
    fwupd.enable = true;
    ananicy = {
      enable = true;
      package = pkgs.ananicy-cpp;
      rulesProvider = pkgs.ananicy-rules-cachyos;
    };
    openssh.enable = true;
    dbus.implementation = "broker";
    power-profiles-daemon.enable = true;
  };
}
