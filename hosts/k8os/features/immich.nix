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
  services.nginx.virtualHosts."k8os" = {
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
