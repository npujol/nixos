{pkgs, ...}: {
  programs.yt-dlp = {
    enable = true;
    settings = {
      cookies-from-browser = "firefox";
      downloader = "aria2c";
    };
  };
}
