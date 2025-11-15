{lib, ...}: {
  # nix.gc.options = "--delete-older-than 14d";
  nix.settings = {
    auto-optimise-store = true;
    experimental-features = ["nix-command" "flakes"];
    substituters = [
      "https://cache.nixos.org"
      "https://leiserfg.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "leiserfg.cachix.org-1:Xm2Z2mX79Bo6LMor9LoH+QGqRNasB++VVCNF0UJh9Fc="
    ];
  };
}
