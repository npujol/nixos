{
  config,
  pkgs,
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
        ];
        extra_records = [
          {
            name = "calibre.nul.com";
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
}
