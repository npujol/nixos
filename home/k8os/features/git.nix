# Defines the git configurations
{lib, ...}: {
  programs.git = {
    enable = true;
    delta.enable = true;
    lfs.enable = true;

    userEmail = "naivy.luna@gmail.com";
    userName = "npujol";
    signing.key = "/home/nainai/.ssh/id_ed25519.pub";
    signing.format = "ssh";

    ignores = [
      ".direnv"
      ".envrc"
    ];

    aliases = {
      # st = "status -sb";
    };

    extraConfig = {
      protocol = {version = 2;};

      rerere = {enabled = true;};
      status = {short = true;};
      diff = {
        algorithm = "histogram";
        indentheuristic = true;
      };
      push = {default = "current";};
      pull = {rebase = true;};
      rebase = {autoStash = true;};
      commit = {gpgsign = true;};
      tag = {gpgsign = true;};
      feature = {manyFiles = true;};
      url = {
        "ssh://git@github.com/" = {
          insteadOf = "https://github.com/";
        };
      };
    };
  };

  programs.gh = {enable = true;};
}
