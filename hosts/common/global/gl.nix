{unstablePkgs, ...}: {
  hardware.graphics = {
    enable = true;
    extraPackages = [unstablePkgs.vulkan-validation-layers];
    enable32Bit = true;
  };
}
