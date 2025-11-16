{...}: {
  xdg.configFile."mimeapps.list".force = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "x-scheme-handler/tg" = "telegram.desktop";
      "inode/directory" = "dolphin.desktop";
      "text/*" = "nvim.desktop";
      "application/zip" = "xarchiver.desktop";
      "application/pdf" = "okular.desktop";
      "application/browser" = "firefox.desktop";
      "text/html" = "firefox.desktop";
    };
  };
}
