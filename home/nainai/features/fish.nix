{unstablePkgs, ...}: {
  programs.fish = {
    enable = true;
    package = unstablePkgs.fish;
    interactiveShellInit = ''
    '';
    shellAliases = {
      "open" = "command xdg-open";
    };
  };
  programs.zoxide = {
    enable = true;
  };
  programs.starship = {
    enable = true;
    enableTransience = true;
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
