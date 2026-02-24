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

  services.nginx.enable = true;
  # `null` will give access to all devices.
  # You may want to restrict this by using something like `[ "/dev/dri/renderD128" ]`
  services.immich.accelerationDevices = null;

  services.nginx.virtualHosts."immich.nul.com" = {
    default = true;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.services.immich.port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
      extraConfig = ''
        client_max_body_size 50000M;
        proxy_read_timeout   600s;
        proxy_send_timeout   600s;
        send_timeout         600s;
      '';
    };
  };
}
