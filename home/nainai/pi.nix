{
  pkgs,
  lib,
  inputs,
  ...
}: let
  extensionsDir = ./pi-extensions;
  extensionFiles = builtins.readDir extensionsDir;

  piPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

  builtinExtensionsDir = "${piPackage}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions";

  builtinExtensionNames = [
    "custom-provider-qwen-cli"
  ];

  extensionEntries = lib.mapAttrs' (
    name: type:
      lib.nameValuePair ".pi/agent/extensions/${name}" {
        source = extensionsDir + "/${name}";
      }
  ) (lib.filterAttrs (name: type: type == "regular") extensionFiles);

  builtinExtensionEntries = lib.listToAttrs (
    map (extName: {
      name = ".pi/agent/extensions/${extName}";
      value = {
        source = "${builtinExtensionsDir}/${extName}";
        recursive = true;
      };
    })
    builtinExtensionNames
  );

  skillsEntries = {
    ".pi/skills/brave-search" = {
      source = ./skills/brave-search;
      recursive = true;
    };
  };

  allFileEntries = lib.mkMerge [
    extensionEntries
    builtinExtensionEntries
    skillsEntries
  ];
in {
  home.packages = [piPackage];

  home.file = allFileEntries;
}
