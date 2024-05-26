{pkgs, ...}: {
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
  virtualisation.docker.autoPrune.enable = true;
}
