{
  config,
  pkgs,
  ...
}: {
  # Enable virtualization with libvirt
  virtualisation.libvirtd = {
    enable = true;
    qemu.package = pkgs.qemu_kvm;
  };

  boot.extraModprobeConfig = "options kvm_intel nested=1";

  # Install tools
  environment.systemPackages = with pkgs; [
    pkgs.virt-manager
  ];

  # Allow libvirt networking
  networking.firewall = {
    checkReversePath = false;
    trustedInterfaces = ["virbr0"];
  };

  programs.virt-manager.enable = true;
}
