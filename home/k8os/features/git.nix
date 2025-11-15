# Defines the git configurations
{lib, ...}: {
  programs.delta.enableGitIntegration = true;
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings.user.email = "naivy.luna@gmail.com";
    settings.user.name = "npujol";
    signing.key = "/home/k8os/.ssh/id_ed25519.pub";
    signing.format = "ssh";

    ignores = [
      ".direnv"
      ".envrc"
    ];

    settings = {
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
