{ ... }:
{
  imports = [
    ./hardware.nix
    ./boot.nix
    ./gaming.nix
    ./gnome.nix
    ./users.nix
    ./ssh.nix
    ./sleep.nix
    ./secrets.nix
    ./home-manager.nix
  ];
  config = {
    networking.hostName = "gary";
  };
}
