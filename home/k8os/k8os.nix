{
  pkgs,
  myPkgs,
  ...
}: {
  imports = [
    ./common.nix
    # ./features/talos-vms.nix
  ];
  #--------------------------------------------------------------------------
  # Here are all the packages that should only be in the desktop configuration
  #--------------------------------------------------------------------------
  home.packages = with pkgs; [
    libvirt
    virt-manager
    kubectl
    kubernetes-helm
    talosctl
    virtiofsd
    bridge-utils
    dnsmasq
    curl
    wget
    jq
    immich
  ];
  services.immich.enable = true;
  services.immich.port = 2283;
}
