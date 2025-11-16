{...}: {
  imports = [];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "thunderbolt"];
  boot.kernelModules = ["kvm-amd" "i2c-dev"];
  boot.initrd.kernelModules = ["amdgpu"];

  boot.kernel.sysctl."vm.max_map_count" = 544288;

  hardware.cpu.amd.updateMicrocode = true;

  nixpkgs.hostPlatform.system = "x86_64-linux";

  boot.initrd.luks.devices."luks-c6b52cb3-460b-413f-a012-7cb41e869390".device = "/dev/disk/by-uuid/c6b52cb3-460b-413f-a012-7cb41e869390";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/c6afbcd3-4ebf-4957-b870-f2f33c902e34";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-10bbcd29-f776-47ac-a652-f8228c04c895".device = "/dev/disk/by-uuid/10bbcd29-f776-47ac-a652-f8228c04c895";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3806-5A84";
    fsType = "vfat";
    options = ["fmask=0022" "dmask=0022"];
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/cd52d1a3-3381-4944-8e82-3cb461f32ae1";}
  ];
}
