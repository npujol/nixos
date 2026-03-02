{ config, lib, pkgs, ... }:

let
  cfg = config.my.neovim;
in
{
  options.my.neovim = {
    enable = lib.mkEnableOption "Neovim with LazyVim configuration";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.neovim ];

    home.file = {
      "${config.xdg.configHome}/nvim/init.lua".source = ./files/nvim/init.lua;
      "${config.xdg.configHome}/nvim/lua".source = ./files/nvim/lua;
      "${config.xdg.configHome}/nvim/colors".source = ./files/nvim/colors;
      "${config.xdg.configHome}/nvim/spell".source = ./files/nvim/spell;
      "${config.xdg.configHome}/nvim/lazyvim.json".source = ./files/nvim/lazyvim.json;
      "${config.xdg.configHome}/nvim/lazy-lock.json".source = ./files/nvim/lazy-lock.json;
      "${config.xdg.configHome}/nvim/.neoconf.json".source = ./files/nvim/.neoconf.json;
      "${config.xdg.configHome}/nvim/stylua.toml".source = ./files/nvim/stylua.toml;
    };

    # German spell file (already defined in common.nix, but we can reference it here)
    home.file."${config.xdg.configHome}/nvim/spell/de.utf-8.spl".source = builtins.fetchurl {
      url = "https://ftp.nluug.nl/pub/vim/runtime/spell/de.utf-8.spl";
      sha256 = "sha256:1ld3hgv1kpdrl4fjc1wwxgk4v74k8lmbkpi1x7dnr19rldz11ivk";
    };

    # Set editor variables
    programs.bash.initExtra = ''
      export EDITOR="nvim"
      export VISUAL="nvim"
    '';
  };
}
