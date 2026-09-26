# Expose the overlay-provided pkgs.herdrPlugins.<name> derivations as
# flat flake outputs so they can be built + smoke-tested in isolation:
#
#   nix build .#herdr-plugin-auto-title
#   nix build .#herdr-plugin-agent-quota
#
# The derivations themselves live at modules/packages/herdr-plugins/*.nix
# and are consumed at runtime via `programs.herdr.plugins.<name>.source`
# in modules/home-manager/programs/herdr.nix. See openspec change
# herdr-plugins-declarative.
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        herdr-plugin-auto-title = pkgs.herdrPlugins.auto-title;
        herdr-plugin-agent-quota = pkgs.herdrPlugins.agent-quota;
      };
    };
}
