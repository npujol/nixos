{...}: {
  imports = [];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "thunderbolt"];
  boot.kernelModules = ["kvm-amd" "i2c-dev"];
  boot.initrd.kernelModules = ["amdgpu"];

  boot.kernel.sysctl."vm.max_map_count" = 544288;

  hardware.cpu.amd.updateMicrocode = true;

  nixpkgs.hostPlatform.system = "x86_64-linux";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/bafbfe48-b336-4f45-bb4e-1385e17b63f0";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0B75-C67A";
    fsType = "vfat";
    options = ["fmask=0077" "dmask=0077"];
  };
}
