{...}: {
  services.paperless = {
    enable = true;
    consumptionDirIsPublic = true;
    settings = {
      PAPERLESS_CONSUMER_IGNORE_PATTERN = [
        ".DS_STORE/*"
        "desktop.ini"
      ];
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
      PAPERLESS_OCR_USER_ARGS = {
        optimize = 1;
        pdfa_image_compression = "lossless";
      };
      PAPERLESS_URL = "https://paperless.nul.com";
    };
  };

  # Traefik dynamic configuration
  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        paperless = {
          rule = "Host(`paperless.nul.com`)";
          service = "paperless";
          entryPoints = ["web"];
        };
      };
      services = {
        paperless = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:28981";}
            ];
          };
        };
      };
    };
  };
}
