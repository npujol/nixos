{pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_6_14;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    blacklistedKernelModules = ["hid-nintendo"];
  };
}
