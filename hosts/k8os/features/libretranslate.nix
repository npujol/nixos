{...}: {
  services.libretranslate = {
    # enable = true;
    port = 8088;
  };

  # Traefik dynamic configuration
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        libretranslate = {
          rule = "Host(`libretranslate.nul.com`)";
          service = "libretranslate";
          entryPoints = ["web"];
        };
      };
      services = {
        libretranslate = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:8088";}
            ];
          };
        };
      };
    };
  };
}
