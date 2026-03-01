{ lib, ... }:
{
  options.dotfiles.gpu = {
    enable = lib.mkEnableOption "GPU acceleration wrapper for non-NixOS systems";

    wrapperType = lib.mkOption {
      type = lib.types.enum [
        "auto"
        "intel"
        "nvidia"
        "mesa"
        "none"
      ];
      default = "none";
      description = ''
        Which nixGL wrapper to use for GPU acceleration.
        Set to 'none' on NixOS systems where it's not needed.
        Set to 'auto' for runtime detection (slower startup).
        Set to specific driver for better performance.
      '';
    };
  };

  # Default to 'none' - profiles that need GPU wrapping will override this
  config.dotfiles.gpu.wrapperType = lib.mkDefault "none";
}
