{ ... }:
{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./home-manager.nix
    ./desktop.nix
    ./gaming.nix
  ];
  config = {
    networking.hostName = "spongebob";

    fileSystems."/data" = {
      device = "/dev/disk/by-label/data";
      fsType = "ext4";
      options = [ "noatime" ];
    };
  };
}
