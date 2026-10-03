{
  pkgs,
  myPkgs,
  config,
  inputs,
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
    myPkgs.eden-emu
    krita
    pdftk
    sqlitebrowser
    yazi
    openrgb
    smartmontools
  ];

  programs.thunderbird = {
    enable = true;
    profiles.nainai.isDefault = true;
  };
}
