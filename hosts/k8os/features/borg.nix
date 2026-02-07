{
  config,
  pkgs,
  ...
}: {
  services.restic.backups = {
    immich = {
      user = "root";
      repository = "sftp://odroid@nas//storage2/backups/immich";
      initialize = true; # initializes the repo, don't set if you want manual control
      passwordFile = "${pkgs.writeText "restic-password" "supersecretpassword"}";
      # paths = [config.services.immich.mediaLocation];
      paths = [
        "/var/lib/immich"
      ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };
  };
}
