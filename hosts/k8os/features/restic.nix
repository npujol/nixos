{config, ...}: let
  bk = {
    name,
    paths,
  }: {
    user = "root";
    repository = "sftp://odroid@nas//storage2/backups/${name}";
    initialize = true; # initializes the repo, don't set if you want manual control
    passwordFile = config.sops.secrets."restic-password".path;
    paths = paths;
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
in {
  sops.secrets."restic-password" = {
    sopsFile = ../../../secrets/secrets.yaml;
    format = "yaml";
  };

  services.restic.backups = {
    immich = bk {
      name = "immich";
      paths = ["/var/lib/immich"];
    };
    memos = bk {
      name = "memos";
      paths = ["/var/lib/memos"];
    };

    vaultwarden = bk {
      name = "vaultwarden";
      paths = ["/var/lib/bitwarden_rs"];
    };
  };
}
