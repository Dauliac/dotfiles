# Expose the overlay-provided statewright derivations as flat flake
# outputs so they can be built + smoke-tested in isolation:
#
#   nix build .#statewright-gateway
#   nix build .#sw-agent
#   nix build .#statewright-tui
#
# The derivations live at modules/packages/statewright.nix. This is the
# packaging half of OpenSpec change `statewright-workflow-layer`
# (beads `do-2oz` gateway, `do-cco` source-built binaries).
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        inherit (pkgs)
          statewright-gateway
          sw-agent
          statewright-tui
          ;
      };
    };
}
