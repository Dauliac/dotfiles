{
  flake.modules.nixos.boot =
    { pkgs, ... }:
    {
      boot = {
        kernelPackages = pkgs.linuxPackages_latest;
        # NOTE: cross platform compilation for raspberry pi
        binfmt.emulatedSystems = [ "aarch64-linux" ];
      };
    };
}
