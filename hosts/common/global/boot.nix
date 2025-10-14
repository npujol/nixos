{pkgs, ...}: {
  boot = {
    kernelPackages = pkgs.linuxPackages_6_16;
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    blacklistedKernelModules = ["hid-nintendo"];
  };
}
