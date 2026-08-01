{pkgs, ...}: {
  home.packages = with pkgs; [
    aria2
  ];

  programs.yt-dlp = {
    enable = true;
    settings = {
      cookies-from-browser = "firefox";
      downloader = "aria2c";
    };
  };
}
