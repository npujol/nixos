{
  pkgs,
  lib,
  inputs,
  ...
}: let
  extensionsDir = ./pi-extensions;
  extensionFiles = builtins.readDir extensionsDir;

  piPackage = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

  builtinExtensionsDir = "${piPackage}/lib/node_modules/@earendil-works/pi-coding-agent/examples/extensions";

  builtinExtensionNames = [
    "custom-provider-qwen-cli"
  ];

  # CLI wrapper for agent-memory (seed.mjs)
  agentMemory = pkgs.writeShellScriptBin "agent-memory" ''
    exec ${pkgs.nodejs}/bin/node ${./memory/seed.mjs} "$@"
  '';

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

  memoryFileEntries = {
    ".pi/agent/APPEND_SYSTEM.md" = {
      source = ./memory/system_append.md;
    };
  };

  skillsEntries = {
    ".pi/skills/brave-search" = {
      source = ./skills/brave-search;
      recursive = true;
    };
    ".pi/skills/commit" = {
      source = ./skills/commit;
      recursive = true;
    };
    ".pi/skills/mermaid" = {
      source = ./skills/mermaid;
      recursive = true;
    };
    ".pi/skills/playwright" = {
      source = ./skills/playwright;
      recursive = true;
    };
  };

  allFileEntries = lib.mkMerge [
    extensionEntries
    builtinExtensionEntries
    skillsEntries
    memoryFileEntries
  ];
in {
  home.packages = [piPackage agentMemory];

  home.file = allFileEntries;
}
