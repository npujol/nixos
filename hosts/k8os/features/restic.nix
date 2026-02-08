{
  config,
  pkgs,
  ...
}: let
  bk = {
    name,
    paths,
  }: {
    user = "root";
    repository = "sftp://odroid@nas//storage2/backups/${name}";
    initialize = true; # initializes the repo, don't set if you want manual control
    passwordFile = "${pkgs.writeText "restic-password" "supersecretpassword"}";
    paths = paths;
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
in {
  services.restic.backups = {
    immich = bk {
      name = "immich";
      paths = ["/var/lib/immich"];
    };
    memos = bk {
      name = "memos";
      paths = ["/var/lib/memos"];
    };
  };
}
