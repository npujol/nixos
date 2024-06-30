
{unstablePkgs, lib, ...}: {
  programs.fish = {
    enable = true;
    package = unstablePkgs.fish;
    interactiveShellInit = ''
    '';
    shellAliases = {
      # Include here other aliases that you want to use only with fish
      "open" = "command xdg-open";
    };
  };

  programs.fzf = {
    enable = true;
    package = unstablePkgs.fzf;
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
      python.symbol = " ";
      hostname.format = "@$hostname ";
      directory = {
        truncation_symbol = "…/";
      };

      right_format = lib.concatStrings [
        "$python"
        "$hostname"
        "$aws"
        "$git_branch"
        "$git_commit"
        "$git_state"
        "$git_metrics"
        "$git_status"
      ];
    };
  };
}
