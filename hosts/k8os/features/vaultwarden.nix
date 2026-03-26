{...}: {
  # Enable the Memos service
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = 8222;
      ROCKET_ADDRESS = "0.0.0.0";
      DISABLE_ADMIN_TOKEN = true; # See the routing rule
    };
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        vaultwarden = {
          rule = "Host(`bw.nul.mywire.org`) && !PathPrefix(`/admin`)";
          service = "vaultwarden";
          entryPoints = ["websecure"];
          # middlewares = ["compress-vw"];
        };
      };
      services = {
        vaultwarden = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:8222";}
            ];
          };
        };
      };
      middlewares.compress-vw.compress = true;
    };
  };
}
