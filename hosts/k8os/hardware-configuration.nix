{...}: {
  imports = [];

  boot.initrd.availableKernelModules = ["xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"];
  boot.kernelModules = ["kvm-amd" "i2c-dev"];
  boot.extraModulePackages = [];

  boot.kernel.sysctl."vm.max_map_count" = 544288;

  hardware.cpu.amd.updateMicrocode = true;

  nixpkgs.hostPlatform.system = "x86_64-linux";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/1354e448-28a6-4309-a535-ec4bfb517896";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0B75-C67A";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };
}
