{
  pkgs,
  myPkgs,
  ...
}: {
  imports = [
    ./common.nix
  ];
  #--------------------------------------------------------------------------
  # Here are all the packages that should only be in the desktop configuration
  #--------------------------------------------------------------------------
  home.packages = with pkgs; [
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
  ];
}
