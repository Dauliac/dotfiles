{
  flake.modules.nixos.gary-boot = {
    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };
  };
}
