{pkgs, ...}: {
  virtualisation.libvirtd = {
    enable = true;
    qemu.package = pkgs.qemu_kvm;
  };

  boot.extraModprobeConfig = "options kvm_intel nested=1";

  environment.systemPackages = with pkgs; [
    virt-manager
  ];

  networking = {
    bridges = {
      br0 = {
        interfaces = ["enp37s0"];
      };
    };
    # Apply network configuration to the bridge
    interfaces.br0 = {
      useDHCP = true;
    };
  };

  programs.virt-manager.enable = true;
}
