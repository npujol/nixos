{...}: {
  # Enable the Memos service
  services.memos = {
    enable = true;
    group = "media";
    dataDir = "/var/lib/memos";
  };

  # Traefik dynamic configuration
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        memos = {
          rule = "Host(`memos.nul.com`)";
          service = "memos";
          entryPoints = ["web"];
        };
      };
      services = {
        memos = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:5230";}
            ];
          };
        };
      };
    };
  };
}
