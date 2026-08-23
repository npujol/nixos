{...}: {
  services.syncthing.enable = true;
  services.syncthing.tray.enable = true;

  services.syncthing.settings = {
    folder = {
      "Local Folders" = {
        path = "/home/nainai/Thunderbird/Mail/Local Folders";
        type = "sendreceive";
        fsScanConcurrency = 2;
        versioning = {
          type = "simple";
          params = {"keep" = "5";};
          cleanupInterval = "30m";
        };
      };
    };
  };
}
