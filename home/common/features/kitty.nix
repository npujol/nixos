{unstablePkgs, ...}: {
  programs.kitty = {
    enable = true;
    package = unstablePkgs.kitty;
    themeFile = "Novel";
    quickAccessTerminalConfig = {
      background_opacity = 0.95;
      lines = 40;
    };

    settings = {
      cursor = "none";
      tab_separator = "│";
      enabled_layouts = "tall,fat";
      enable_audio_bell = false;
      background_opacity = 0.95;

      # Have to force it because some symbols are loaded from djavu otherwise
      symbol_map = "U+23FB-U+23FE,U+2665,U+26A1,U+2B58,U+E000-U+E00A,U+E0A0-U+E0A3,U+E0B0-U+E0C8,U+E0CA,U+E0CC-U+E0D2,U+E0D4,U+E200-U+E2A9,U+E300-U+E3E3,U+E5FA-U+E634,U+E700-U+E7C5,U+EA60-U+EBEB,U+F000-U+F2E0,U+F300-U+F32F,U+F400-U+F4A9,U+F500-U+F8FF,U+FD0B Symbols Nerd Font Mono";
    };
    keybindings = {
      "ctrl+F1" = "launch --allow-remote-control kitty +kitten broadcast";
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+enter" = "new_window_with_cwd";
    };
  };
}
