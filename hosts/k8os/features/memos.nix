{...}: {
  # Enable the Memos service
  services.memos = {
    enable = true;
    group = "media";
    dataDir = "/var/lib/memos";
  };

  services.nginx.virtualHosts."memos.nul.com" = {
    locations."/" = {
      extraConfig = "
        proxy_pass           http://127.0.0.1:5230;
        proxy_set_header     Host $host;
        proxy_set_header     X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header     X-Scheme        $scheme;
        client_max_body_size 1024M;
      ";
    };
  };
}
