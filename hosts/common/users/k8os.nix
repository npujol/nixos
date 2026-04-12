{pkgs, ...}: {
  users.mutableUsers = true; # Allow changing the password via `passwd`
  users.users.k8os = {
    isNormalUser = true;
    description = "k8os";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
    ];
    shell = pkgs.fish;
  };
}
