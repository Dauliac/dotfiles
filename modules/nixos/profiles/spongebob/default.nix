{ ... }:
{
  imports = [
    # ./hardware.nix
    ./disko.nix
  ];
  config = {
    networking.hostName = "nixos";
  };
}
