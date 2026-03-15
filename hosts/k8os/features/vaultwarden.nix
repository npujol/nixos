{...}: {
  # Enable the Memos service
  services.vaultwarden = {
    enable = true;
  };

  # Traefik dynamic configuration
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        memos = {
          rule = "Host(`vaultwarden.nul.com`)";
          service = "vaultwarden";
          entryPoints = ["web"];
        };
      };
      services = {
        memos = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:8222";}
            ];
          };
        };
      };
    };
  };
}
