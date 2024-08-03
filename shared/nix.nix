{lib, ...}: {
  nix.gc.options = "--delete-older-than 14d";
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = ["nix-command" "flakes" "repl-flake"];
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
}
