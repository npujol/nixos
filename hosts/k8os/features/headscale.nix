{
  config,
  pkgs,
  inputs,
  ...
}: {
  services.headscale = {
    enable = true;

    # Nested settings for Headscale's internal configuration
    settings = {
      server_url = "https://hs.nul.mywire.org";
      dns = {
        magic_dns = true;
        base_domain = "nul.com";
        nameservers.global = [
          "1.1.1.1"
          "1.0.0.1"
          "2606:4700:4700::1111"
          "2606:4700:4700::1001"
        ];
        extra_records = [
          {
            name = "calibre.nul.com";
            type = "A";
            value = "100.64.0.12";
          }
          {
            name = "immich.nul.com";
            type = "A";
            value = "100.64.0.12";
          }
          {
            name = "memos.nul.com";
            type = "A";
            value = "100.64.0.12";
          }
          {
            name = "paperless.nul.com";
            type = "A";
            value = "100.64.0.12";
          }
          {
            name = "languagetool.nul.com";
            type = "A";
            value = "100.64.0.12";
          }
          {
            name = "libretranslate.nul.com";
            type = "A";
            value = "100.64.0.12";
          }
          {
            name = "ltfrontend.nul.com";
            type = "A";
            value = "100.64.0.12";
          }
        ];
      };

      databases.sqlite.path = "/var/lib/headscale/db.sqlite";
    };
  };

  services.static-web-server = {
    # enable = true;
    root = inputs.headscale-admin;
    listen = "::1:5000";
    configuration = {
      general = {
        directory-listing = true;
      };
    };
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        hs = {
          rule = "Host(`hs.nul.mywire.org`)";
          service = "hs";
          entryPoints = ["websecure"];
          middlewares = ["cors"];
        };

        hs-admin = {
          rule = "Host(`hs.nul.mywire.org`) && PathPrefix(`/admin`)";
          service = "hs-admin";
          entryPoints = ["websecure"];
          middlewares = ["pref"];
        };
      };

      services = {
        hs = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:8080";}
            ];
          };
        };

        hs-admin = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:5000";}
            ];
          };
        };
      };

      middlewares.cors.headers = {
        accesscontrolallowmethods = "GET,POST,PUT,PATCH,DELETE,OPTIONS";
        accesscontrolallowheaders = "*";
        accesscontrolalloworiginlist = "";
        accesscontrolmaxage = 100;
        addvaryheader = true;
      };
      middlewares.pref.stripPrefix.prefixes = ["/admin"];
    };
  };
}
