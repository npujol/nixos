{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];

  sops = {
    age = {
      # Use SSH host key for age encryption
      # keyFile = "/etc/ssh/ssh_host_ed25519_key";

      keyFile = "/var/lib/sops-nix/key.txt";
    };
  };
}
