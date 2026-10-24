{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    sops
    age
    ssh-to-age
  ];

  sops.age.keyFile = "/home/nainai/.config/sops/age/keys.txt";
}
