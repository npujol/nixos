{ config, pkgs, lib, ... }:

{
  # Enable virtualization
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
          secureBoot = true;
          tpmSupport = true;
        }).fd];
      };
    };
  };

  # Enable KVM nested virtualization for AMD
  boot.extraModprobeConfig = ''
    options kvm_amd nested=1
  '';

  # Required packages for managing Talos cluster
  environment.systemPackages = with pkgs; [
    # Kubernetes tools
    kubectl
    kubernetes-helm
    
    # Talos CLI
    talosctl
    
    # VM management
    virt-manager
    virtiofsd
    
    # Network tools
    bridge-utils
    dnsmasq
    
    # Utilities
    curl
    wget
    jq
  ];

  # Add your user to libvirt group
  users.users.k8os = {
    extraGroups = [ "libvirtd" ];
  };

  # Configure networking for VMs
  networking = {
    bridges = {
      br0 = {
        interfaces = [ ];
      };
    };
    
    interfaces = {
      br0 = {
        ipv4.addresses = [{
          address = "192.168.100.1";
          prefixLength = 24;
        }];
      };
    };
    
    nat = {
      enable = true;
      internalInterfaces = [ "br0" ];
      externalInterface = "enp0s31f6";  # Adjust to your interface
    };

    firewall = {
      enable = true;
      trustedInterfaces = [ "br0" ];
      allowedTCPPorts = [ 6443 ];  # Kubernetes API
    };
  };

  # dnsmasq for DHCP on bridge
  services.dnsmasq = {
    enable = true;
    settings = {
      interface = "br0";
      bind-interfaces = true;
      dhcp-range = [ "192.168.100.10,192.168.100.100,24h" ];
      dhcp-option = [ "3,192.168.100.1" ];  # Gateway
    };
  };
}