{
  description = "My nix config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    leiserfg-overlay.url = "github:leiserfg/leiserfg-overlay";
    llm-agents = {
      url = "github:numtide/llm-agents.nix";

      inputs.nixpkgs.follows = "nixpkgs"; # I don't wanna use the cache
    };
  };

  outputs = {
    nixos-hardware,
    nixpkgs,
    home-manager,
    plasma-manager,
    ...
  } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      # "aarch64-linux"
      # "i686-linux"
      # "aarch64-darwin"
      # "x86_64-darwin"
    ];

    unstablePackages = forAllSystems (
      system:
        import inputs.nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        }
    );
  in rec {
    overlays = {
      default = import ./overlay {inherit inputs;};
    };

    # Reusable nixos modules you might want to export
    # These are usually stuff you would upstream into nixpkgs
    nixosModules = import ./modules/nixos;
    # Reusable home-manager modules you might want to export
    # These are usually stuff you would upstream into home-manager
    homeModules = import ./modules/home-manager;

    # Devshell for bootstrapping
    # Accessible through 'nix develop' or 'nix-shell' (legacy)
    devShells = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix {};
    });

    legacyPackages = forAllSystems (
      system:
        import inputs.nixpkgs {
          inherit system;
          overlays =
            (builtins.attrValues overlays)
            ++ [
              # inputs.blender.overlays.default
            ];
          config.allowUnfree = true;
          config.permittedInsecurePackages = [];
        }
    );

    nixosConfigurations = {
      fnixy = nixpkgs.lib.nixosSystem {
        pkgs = legacyPackages.x86_64-linux;
        specialArgs = {
          inherit inputs;
          unstablePkgs = unstablePackages.x86_64-linux;
        };
        modules =
          (builtins.attrValues nixosModules)
          ++ [
            nixos-hardware.nixosModules.framework-13-7040-amd
            ./hosts/fnixy
          ];
      };
      limbo = nixpkgs.lib.nixosSystem {
        pkgs = legacyPackages.x86_64-linux;
        specialArgs = {
          inherit inputs;
          unstablePkgs = unstablePackages.x86_64-linux;
        };
        modules =
          (builtins.attrValues nixosModules)
          ++ [
            ./hosts/limbo
          ];
      };
      k8os = nixpkgs.lib.nixosSystem {
        pkgs = legacyPackages.x86_64-linux;
        specialArgs = {
          inherit inputs;
          unstablePkgs = unstablePackages.x86_64-linux;
        };
        modules =
          (builtins.attrValues nixosModules)
          ++ [
            ./hosts/k8os
          ];
      };
    };

    homeConfigurations = {
      "nainai@fnixy" = home-manager.lib.homeManagerConfiguration {
        pkgs = legacyPackages.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs;
          unstablePkgs = unstablePackages.x86_64-linux;
          myPkgs = inputs.leiserfg-overlay.packages.x86_64-linux;
        };
        modules =
          (builtins.attrValues homeModules)
          ++ [
            inputs.plasma-manager.homeModules.plasma-manager
            ./home/nainai/fnixy.nix
          ];
      };

      "nainai@limbo" = home-manager.lib.homeManagerConfiguration {
        pkgs = legacyPackages.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs;
          unstablePkgs = unstablePackages.x86_64-linux;
          myPkgs = inputs.leiserfg-overlay.packages.x86_64-linux;
        };
        modules =
          (builtins.attrValues homeModules)
          ++ [
            inputs.plasma-manager.homeModules.plasma-manager
            ./home/nainai/limbo.nix
          ];
      };

      "k8os@k8os" = home-manager.lib.homeManagerConfiguration {
        pkgs = legacyPackages.x86_64-linux;
        extraSpecialArgs = {
          inherit inputs;
          unstablePkgs = unstablePackages.x86_64-linux;
          myPkgs = inputs.leiserfg-overlay.packages.x86_64-linux;
        };
        modules =
          (builtins.attrValues homeModules)
          ++ [
            inputs.plasma-manager.homeModules.plasma-manager
            ./home/k8os/k8os.nix
          ];
      };
    };

    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
