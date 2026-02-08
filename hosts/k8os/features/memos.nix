{...}: {
  # Enable the Memos service
  services.memos = {
    enable = true;
    port = 5230;
    host = "127.0.0.1"; # Or 127.0.0.1 if behind a reverse proxy
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
