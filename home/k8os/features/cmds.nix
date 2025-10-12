# Add custom scripts to packages
{pkgs, ...}: {
  home.packages = with pkgs; [
    # (writeShellScriptBin "mpvyt" ''
    #   mpv --no-video --ytdl-format=bestaudio ytdl://ytsearch10:"$@";
    # '')
  ];
}
