{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../common/global
    ../common/users/nainai.nix
    ../common/features/docker.nix
    ../common/features/opensnitch.nix
    ../common/features/sops.nix
    inputs.sops-nix.nixosModules.sops
  ];

  networking.hostName = "fnixy";
  networking.firewall.enable = false;
  programs.nh.flake = "/home/nainai/projects/nix-config";

  # SOPS secrets — decrypted at boot and placed in /run/secrets/<name>
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.secrets = {
    "github-token" = {
      sopsFile = ../../secrets/secrets.yaml;
      format = "yaml";
      owner = "nainai";
      group = "users";
      mode = "0600";
    };
    "obsidian-api-key" = {
      sopsFile = ../../secrets/secrets.yaml;
      format = "yaml";
      owner = "nainai";
      group = "users";
      mode = "0600";
    };
    "restic-password" = {
      sopsFile = ../../secrets/secrets.yaml;
      format = "yaml";
    };
  };
  # set vram to grow to 20Gb
  boot.kernelParams = let
    gttGiB = 20;
    gttMiB = gttGiB * 1024;
    pageSizeKiB = 4;
    ttmPages = (gttMiB * 1024) / pageSizeKiB; # Convert MiB -> KiB, then divide by 4 KiB per page
  in [
    "amdgpu.gttsize=${toString gttMiB}"
    "ttm.pages_limit=${toString ttmPages}"
    "ttm.page_pool_size=${toString ttmPages}"
  ];
}
