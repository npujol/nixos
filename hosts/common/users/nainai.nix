{
  pkgs,
  config,
  ...
}: let
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in {
  users.mutableUsers = true; # Allow changing the password via `passwd`
  users.users.nainai = {
    isNormalUser = true;
    description = "nainai";
    extraGroups = ["networkmanager" "wheel"];
    shell = pkgs.fish;
  };
}
