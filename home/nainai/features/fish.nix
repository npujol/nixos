{
  unstablePkgs,
  lib,
  ...
}: {
  programs.fish = {
    enable = true;
    package = unstablePkgs.fish;
    interactiveShellInit = ''
    '';
    shellAliases = {
      # Include here other aliases that you want to use only with fish
      "open" = "command xdg-open";
      "smwitch-syste" = "sudo nixos-rebuild switch --flake .";
      "switch-home" = "home-manager switch --flake . -b backup";
    };
  };

  programs.fzf = {
    enable = true;
    package = unstablePkgs.fzf;
  };

  programs.zoxide = {
    enable = true;
  };

  # https://starship.rs/guide/
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = lib.concatStrings [
        "$directory"
        "$character"
      ];
      git_branch.format = "[$symbol$branch(:$remote_branch)]($style)";

      python.format = "[\${symbol}\${version} ]($style)";
      python.symbol = "🐍 ";
      python.style = "bold green";

      golang.format = "[\${symbol}\${version} ]($style)";
      golang.symbol = "🐹 ";
      golang.detect_files = [
        "go.mod"
        "go.sum"
      ];

      kubernetes.symbol = "⎈ ";
      kubernetes.format = " [$symbol$context( \\($namespace\\))]($style) ";
      kubernetes.style = "bright-blue";

      helm.format = "[$symbol $version](bold white) ";
      helm.symbol = "⛵";

      hostname.format = "@$hostname ";
      directory = {
        truncation_symbol = "…/";
      };

      right_format = lib.concatStrings [
        "$python"
        "$golang"
        "$hostname"
        "$aws"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
        "$kubernetes"
        "$docker_context"
        "$helm"
        "$terraform"
        "$typst"
        "$nix_shell"
        "$direnv"
        "$container"
      ];
    };
  };
}
