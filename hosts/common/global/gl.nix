{
  pkgs,
  unstablePkgs,
  lib,
  inputs,
  ...
}: {
  hardware.graphics = {
    enable = true;
    extraPackages = [unstablePkgs.vulkan-validation-layers];
    # package = unstablePkgs.mesa.drivers;
    # package32 = unstablePkgs.pkgsi686Linux.mesa.drivers;
  };
}
