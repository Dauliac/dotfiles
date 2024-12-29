{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    ./treefmt.nix
    ./build.nix
    ./dev.nix
    ./test.nix
  ];
}
