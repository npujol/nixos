{pkgs, ...}: {
  users.groups.media = {};

  users.users.calibre-web = {
    isSystemUser = true;
    group = "media";
  };

  services.calibre-web = {
    enable = true;
    group = "media";
    package = pkgs.calibre-web.overridePythonAttrs {
      pythonRelaxDeps = [
        "wand"
        "regex"
        "flask-babel"
        "pypdf"
        "lxml"
      ];
    };
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
          # &&
          rule = "Host(`calibre.locus.mywire.org`) && ClientIP(`100.64.0.0/24`)";
          service = "calibre";
          entryPoints = ["websecure"];
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
