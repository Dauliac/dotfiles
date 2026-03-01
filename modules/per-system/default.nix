# Per-system flake-parts modules - auto-imported by import-tree
# No imports needed - other modules are automatically discovered
{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];
  debug = true;
}
