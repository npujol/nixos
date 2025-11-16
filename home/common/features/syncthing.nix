{lib, ...}: {
  services.trayscale = {
    enable = true;
  };

  services.syncthing.enable = true; # Enable the syncthing service
  services.syncthing.tray.enable = true; # Enable the syncthing tray
  # Workaround to add a target in KDE
  systemd.user.targets.tray = {
    Unit = {
      Description = "Home Manager System Tray";
      Requires = ["graphical-session-pre.target"];
    };
  };
}
