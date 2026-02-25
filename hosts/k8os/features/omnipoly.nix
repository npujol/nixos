{
  config,
  pkgs,
  ...
}: {
  virtualisation.oci-containers.containers = {
    omnipoly = {
      image = "kweg/omnipoly:latest";
      autoStart = true;
      ports = ["8085:80"];

      environment = {
        LANGUAGE_TOOL = "http://127.0.0.1:8089";
        LANGUAGE_TOOL_PICKY = "true";
        LIBRETRANSLATE = "http://127.0.0.1:8088";
        THEME = "dark";

        # Optional: Limit translation languages (ISO 639 codes)
        # LIBRETRANSLATE_LANGUAGES = "[\"en\", \"pl\", \"es\"]";

        # Optional: Limit grammar check languages (language-Region codes)
        # LANGUAGE_TOOL_LANGUAGES = "[\"en-GB\", \"pl-PL\", \"es-ES\"]";

        # Optional: Disable dictionary feature
        # DISABLE_DICTIONARY = "true";

        # Optional: Enable debug logging
        # DEBUG = "true";
      };

      labels = {
        "app" = "omnipoly";
        "description" = "Language workflow frontend";
      };

      log-driver = "journald";
    };
  };

  # Optional: If your services run on the same host (localhost), you need special networking
  # This extra configuration makes localhost inside the container point to your host
  virtualisation.oci-containers.containers.omnipoly.extraOptions = [
    "--add-host=host.docker.internal:host-gateway" # For Docker
    # "--add-host=host.containers.internal:host-gateway"  # For Podman
  ];

  services.nginx.virtualHosts."languagetool.nul.com" = {
    locations."/" = {
      extraConfig = "
        proxy_pass           http://127.0.0.1:8085;
        proxy_set_header     Host $host;
        proxy_set_header     X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header     X-Scheme        $scheme;
        client_max_body_size 1024M;
      ";
    };
  };
}
