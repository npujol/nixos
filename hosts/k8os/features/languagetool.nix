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
          rule = "Host(`languagetool.locus.mywire.org`) && ClientIP(`100.64.0.0/24`)";
          service = "languagetool";
          entryPoints = ["websecure"];
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
