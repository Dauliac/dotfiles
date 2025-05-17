{ ... }:
{
  imports = [
    ./disko.nix
    ./gaming.nix
    ./hardware.nix
    ./users.nix
    ./home-manager.nix
    ./desktop.nix
    ./secrets.nix
    ./boot.nix
  ];
  config = {
    networking.hostName = "nixos";
  };
}
