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
  };
}
