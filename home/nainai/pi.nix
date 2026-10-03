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

  mcpEntries = {
    ".pi/agent/mcp.json" = {
      text = builtins.toJSON {
        mcpServers = {
          obsidian = {
            url = "http://127.0.0.1:27200/mcp";
            headers = {
              # pi expands env vars in headers at runtime; Nix doesn't interpolate "$ + "{...}""
              Authorization = "$" + "{OBSIDIAN_MCP_TOKEN}";
            };
            description = "Obsidian vault — semantic search, file management, templates, command execution";
          };
          github = {
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-github"
            ];
            env.GITHUB_TOKEN = "$" + "{GH_TOKEN}";
            description = "GitHub — repositories, issues, PRs, code search";
          };
        };
      };
    };
  };

  skillsEntries = {
    ".pi/skills/brave-search" = {
      source = ./skills/brave-search;
      recursive = true;
    };
    ".pi/skills/check-review-comments" = {
      source = ./skills/check-review-comments;
      recursive = true;
    };
    ".pi/skills/commit" = {
      source = ./skills/commit;
      recursive = true;
    };
    ".pi/skills/fact-check" = {
      source = ./skills/fact-check;
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
    ".pi/skills/refactor-comments" = {
      source = ./skills/refactor-comments;
      recursive = true;
    };
    ".pi/skills/refactor-patterns" = {
      source = ./skills/refactor-patterns;
      recursive = true;
    };
    ".pi/skills/update-changelog" = {
      source = ./skills/update-changelog;
      recursive = true;
    };
  };

  allFileEntries = lib.mkMerge [
    extensionEntries
    builtinExtensionEntries
    skillsEntries
    memoryFileEntries
    mcpEntries
  ];
in {
  home.packages = [piPackage agentMemory];

  home.file = allFileEntries;
}
