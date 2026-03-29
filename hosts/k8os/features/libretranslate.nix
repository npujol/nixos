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
          rule = "Host(`libretranslate.locus.mywire.org`) && ClientIP(`100.64.0.0/24`)";
          service = "libretranslate";
          entryPoints = ["websecure"];
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
