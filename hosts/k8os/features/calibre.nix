{...}: {
  users.groups.media = {}; # Add this line

  users.users.calibre-web = {
    isSystemUser = true;
    group = "media";
  };

  # Calibre-Web
  services.calibre-web = {
    enable = true;
    group = "media";
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

  services.nginx.virtualHosts."calibre.nul.com" = {
    locations."/" = {
      extraConfig = "
        proxy_pass           http://127.0.0.1:8083;
        proxy_set_header     Host $host;
        proxy_set_header     X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header     X-Scheme        $scheme;
        client_max_body_size 1024M;
      ";
    };
  };
}
