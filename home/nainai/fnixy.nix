{
  pkgs,
  inputs,
  config,
  ...
}: {
  imports = [
    ./common.nix
    ./pi.nix
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultAgePrivateKeyPath = "/home/nainai/.config/sops/age/keys.txt";
    secrets = {
      "github-token" = {
        sopsFile = ../../secrets/secrets.yaml;
        format = "yaml";
      };
      "obsidian-api-key" = {
        sopsFile = ../../secrets/secrets.yaml;
        format = "yaml";
      };
    };
  };

  home.sessionVariables = {
    GH_TOKEN = config.sops.secrets."github-token".value;
    OBSIDIAN_API_KEY = config.sops.secrets."obsidian-api-key".value;
  };

  home.packages = with pkgs; [
    nix-tree
    zoom-us
  ];
  manual.manpages.enable = false; # Doc framework is broken, so let's stop updating this
  services.opensnitch-ui.enable = true;

  programs.thunderbird = {
    enable = true;
    profiles.nainai.isDefault = true;
  };
}
