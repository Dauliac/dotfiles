{ ... }:
{
  imports = [
    ./disko.nix
    ./hardware.nix
    ./boot.nix
  ];
  config = {
    networking.hostName = "nixos";
  };
}
