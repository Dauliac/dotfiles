{ ... }:
{
  imports = [
    ./nixos.nix
    ./home-manager.nix
    ./flake-parts
    ./modules.nix
    ./system-manager.nix
  ];
}
