{config, pkgs, lib, inputs, ...}:
let
  extensionsDir = ./pi-extensions;
  extensionFiles = builtins.readDir extensionsDir;

  # Reference to the pi package
  piPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

  # Directory containing builtin extensions
  builtinExtensionsDir = "${piPackage}/lib/node_modules/@mariozechner/pi-coding-agent/examples/extensions";

  # List of builtin extension names to include
  builtinExtensionNames = [
    "custom-provider-qwen-cli"
  ];

  # Create home.file entries for each local extension
  extensionEntries = lib.mapAttrs' (
    name: type:
    lib.nameValuePair ".pi/agent/extensions/${name}" {
      source = extensionsDir + "/${name}";
    }
  ) (lib.filterAttrs (name: type: type == "regular") extensionFiles);

  # Create home.file entries for builtin extensions
  builtinExtensionEntries = lib.listToAttrs (
    map (extName: {
      name = ".pi/agent/extensions/${extName}";
      value = {
        source = "${builtinExtensionsDir}/${extName}";
        recursive = true;
      };
    }) builtinExtensionNames
  );

  # Skills entries
  skillsEntries = {
    ".pi/skills/brave-search" = {
      source = ./skills/brave-search;
      recursive = true;
    };
  };

  # Combine all entries
  allFileEntries = lib.mkMerge [
    extensionEntries
    builtinExtensionEntries
    skillsEntries
  ];

in
{
  home.packages = [ piPackage ];

  home.file = allFileEntries;
}
