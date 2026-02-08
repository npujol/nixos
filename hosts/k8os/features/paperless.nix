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

  services.nginx.virtualHosts."paperless.nul.com" = {
    locations."/" = {
      extraConfig = "
        proxy_pass           http://127.0.0.1:28981;
        proxy_set_header     Host $host;
        proxy_set_header     X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header     X-Scheme        $scheme;
        client_max_body_size 1024M;
      ";
    };
  };
}
