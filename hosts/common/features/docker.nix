{...}: {
  virtualisation.docker.enable = true;

  virtualisation.docker.autoPrune.enable = true;
  virtualisation.docker.daemon.settings = {
    data-root = "/home/nainai/docker_root/";
  };
}
