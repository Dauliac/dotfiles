{ ... }:
{
  imports = [
    ./nixos.nix
    ./home-manager.nix
    ./build-system
    ./modules.nix
    ./system-manager.nix
  ];
}
