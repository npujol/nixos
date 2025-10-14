{...}: {
  imports = [];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "thunderbolt"];
  boot.kernelModules = ["kvm-amd" "i2c-dev"];
  boot.initrd.kernelModules = ["amdgpu"];

  boot.kernel.sysctl."vm.max_map_count" = 544288;

  hardware.cpu.amd.updateMicrocode = true;

  nixpkgs.hostPlatform.system = "x86_64-linux";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/c4f07611-9be5-4978-930c-c66e1be044b0";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6437-ADEE";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/c4d0a86d-6982-4c3a-b278-8a920a023c81";
    fsType = "ext4";
  };
}
