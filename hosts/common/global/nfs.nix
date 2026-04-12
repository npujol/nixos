{pkgs, ...}: {
  services = {
    autofs = {
      enable = true;
      autoMaster = ''
        /net -hosts  --timeout=60
      '';
    };
    rpcbind.enable = true;
  };
  environment.systemPackages = with pkgs; [
    nfs-utils
  ];
}
