{{ config, pkgs, ... }:

{
  # Enable virtualization with libvirt
  virtualisation.libvirtd = {
    enable = true;
    qemu.package = pkgs.qemu_kvm;
  };

  # Enable KVM for AMD
  boot.extraModprobeConfig = "options kvm_amd nested=1";

  # Install tools
  environment.systemPackages = with pkgs; [
    virt-manager
    kubectl
    kubernetes-helm
    talosctl
  ];

  # Allow libvirt networking
  networking.firewall = {
    checkReversePath = false;
    trustedInterfaces = [ "virbr0" ];
  };
}