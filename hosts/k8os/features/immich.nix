{
  config,
  lib,
  ...
}: {
  users.users.immich.extraGroups = [
    "video"
    "render"
  ];
  services.immich.enable = true;
  services.immich.port = 2283;

  # Traefik dynamic configuration
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        immich = {
          rule = "Host(`immich.nul.com`)";
          service = "immich";
          entryPoints = ["web"];
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
      };
      middlewares = {
        immich-compress = {
          compress = true;
        };
      };
    };
  };

  # `null` will give access to all devices.
  # You may want to restrict this by using something like `[ "/dev/dri/renderD128" ]`
  services.immich.accelerationDevices = null;
}
