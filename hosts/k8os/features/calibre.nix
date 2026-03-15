{...}: {
  users.groups.media = {}; # Add this line

  users.users.calibre-web = {
    isSystemUser = true;
    group = "media";
  };

  # Calibre-Web
  services.calibre-web = {
    enable = true;
    group = "media";
    options = {
      calibreLibrary = "/var/lib/calibre-library";
      enableBookUploading = true;
      reverseProxyAuth.enable = true;
      reverseProxyAuth.header = "admin";
    };
    listen = {
      ip = "127.0.0.1";
      port = 8083;
    };
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        calibre = {
          rule = "Host(`calibre.nul.com`)";
          service = "calibre";
          entryPoints = ["web"];
        };
      };
      services = {
        calibre = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:8083";}
            ];
          };
        };
      };
    };
  };
}
