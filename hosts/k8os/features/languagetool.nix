{...}: {
  services.languagetool = {
    enable = true;
    port = 8089;
    jvmOptions = ["-Xmx1g"];
  };

  services.nginx.virtualHosts."languagetool.nul.com" = {
    locations."/" = {
      extraConfig = "
        proxy_pass           http://127.0.0.1:8089;
        proxy_set_header     Host $host;
        proxy_set_header     X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header     X-Scheme        $scheme;
        client_max_body_size 1024M;
      ";
    };
  };
}
