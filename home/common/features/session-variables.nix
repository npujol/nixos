{pkgs, ...}: {
  home.sessionVariables = {
    BROWSER = "firefox";
    TERMCMD = "kitty";
    EDITOR = "neovim";
    ALSOFT_DRIVERS = "pulse";
    NIXOS_OZONE_WL = 1;
  };
}
