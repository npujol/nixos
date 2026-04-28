{config, ...}: {
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];
  services.immich.enable = true;
  services.immich.port = 2283;
  # `null` will give access to all devices.
  # You may want to restrict this by using something like `[ "/dev/dri/renderD128" ]`
  services.immich.accelerationDevices = null;

  services.immich-public-proxy.enable = true;
  services.immich-public-proxy.immichUrl = "http://localhost:${toString config.services.immich.port}";

  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        immich = {
          rule = "Host(`immich.locus.mywire.org`) && ClientIP(`100.64.0.0/24`)";
          service = "immich";
          entryPoints = ["websecure"];
          middlewares = ["immich-compress"];
        };
        album = {
          rule = "Host(`album.locus.mywire.org`)"; # This one is public, so no tailscale filter
          service = "album";
          entryPoints = ["websecure"];
          middlewares = ["immich-compress"];
        };
      };
      services = {
        immich = {
          loadBalancer = {
            servers = [
              {url = "http://[::1]:${toString config.services.immich.port}";}
            ];
          };
        };
        album = {
          loadBalancer = {
            servers = [
              {url = "http://[::1]:${toString config.services.immich-public-proxy.port}";}
            ];
          };
        };
      };
      middlewares = {
        immich-compress = {
          compress = true;
        };
      };
    };
  };
}
