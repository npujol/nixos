{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.my.neovim;
in {
  options.my.neovim = {
    enable = lib.mkEnableOption "Neovim with LazyVim configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.neovim];
    home.file = {
      "${config.xdg.configHome}/nvim/init.lua".source = ./files/nvim/init.lua;
      "${config.xdg.configHome}/nvim/lua" = {
        source = ./files/nvim/lua;
        recursive = true;
      };
      "${config.xdg.configHome}/nvim/colors" = {
        source = ./files/nvim/colors;
        recursive = true;
      };
      "${config.xdg.configHome}/nvim/plugin" = {
        source = ./files/nvim/plugin;
        recursive = true;
      };
      "${config.xdg.configHome}/nvim/.neoconf.json".source = ./files/nvim/.neoconf.json;
      "${config.xdg.configHome}/nvim/stylua.toml".source = ./files/nvim/stylua.toml;
    };

    # Set editor variables
    programs.bash.initExtra = ''
      export EDITOR="nvim"
      export VISUAL="nvim"
    '';
  };
}
