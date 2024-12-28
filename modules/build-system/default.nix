{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    ./treefmt.nix
    ./checks.nix
    ./dev.nix
    ./test.nix
  ];
}
