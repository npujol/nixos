{pkgs, ...}: {
  users.mutableUsers = true; # Allow changing the password via `passwd`
  users.users.nainai = {
    isNormalUser = true;
    description = "nainai";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    shell = pkgs.fish;
  };
}
