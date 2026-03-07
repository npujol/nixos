{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.skills;
in
{
  options.skills = {
    raw_paths = lib.mkOption {
      type = with lib.types; listOf path;
      default = [];
      description = "List of directories containing raw skill definitions";
    };

    entries = lib.mkOption {
      type = with lib.types; attrsOf (submodule ({
        name,
        config,
        options,
        ...
      }: {
        resources = lib.mkOption {
          type = with lib.types; attrsOf package;
          default = {};
          description = "Resources (executables) available to this skill";
        };

        description = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Description of what this skill does";
        };

        instructions = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Instructions for using this skill";
        };
      }));
      default = {};
      description = "Skill definitions with their resources and instructions";
    };
  };

  config = let
    # File entries for structured skills
    skillFileEntries = lib.mapAttrs' (
      name: skill:
      lib.nameValuePair ".pi/skills/${name}" {
        text = ''
          # Skill: ${name}
          ${skill.description}

          ## Instructions
          ${skill.instructions { ${name} = "\${aliases.${name}}"; }}
        '';
      }
    ) cfg.entries;

    # File entries for raw skill directories
    rawSkillEntries = lib.listToAttrs (
      map (rawPath: {
        name = ".pi/skills/${rawPath.baseName}";
        value = {
          source = rawPath;
          recursive = true;
        };
      }) cfg.raw_paths
    );
  in lib.mkIf (cfg.entries != {} || cfg.raw_paths != []) {
    home.packages = lib.concatLists (lib.mapAttrsToList (name: skill: lib.attrValues skill.resources) cfg.entries);

    home.file = lib.mkMerge [
      skillFileEntries
      rawSkillEntries
    ];
  };
}
