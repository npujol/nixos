{...}: {
  services.languagetool = {
    enable = true;
    port = 8089;
    jvmOptions = ["-Xmx1g"];
  };

  services.traefik.dynamicConfigOptions = {
    http = {
      routers = {
        languagetool = {
          rule = "Host(`languagetool.nul.com`)";
          service = "languagetool";
          entryPoints = ["web"];
        };
      };
      services = {
        languagetool = {
          loadBalancer = {
            servers = [
              {url = "http://127.0.0.1:8089";}
            ];
          };
        };
      };
    };
  };
}
