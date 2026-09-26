# Bag-of-packages for declaratively-built herdr plugins. See openspec
# change herdr-plugins-declarative.
#
# The outer overlay (modules/packages/default.nix) calls this via
# `herdrPlugins = final.callPackage ./herdr-plugins { };` so the two
# derivations below land at `pkgs.herdrPlugins.auto-title` and
# `pkgs.herdrPlugins.agent-quota`.
#
# Each per-plugin derivation is self-contained (its own toolchain,
# hashes, install layout) and shares only a small snippet that
# fail-closes on manifest-id drift — see spec `herdr/plugin-build`.
{ callPackage, rustPlatform }:
let
  # Sanity check spliced into every plugin's `postInstall`: refuses to
  # produce a store path if the checked-in herdr-plugin.toml's `id`
  # doesn't match what the derivation declares. Cheap at build time,
  # painful to debug at herdr activation time (kevinpita's module would
  # report the plugin as absent from the registry with no obvious cause).
  installManifest = id: ''
    manifest_id=$(sed -nE 's/^id[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' herdr-plugin.toml | head -1)
    if [ "$manifest_id" != "${id}" ]; then
      echo "ERROR: manifest id ($manifest_id) does not match declared id (${id})" >&2
      exit 1
    fi
    cp herdr-plugin.toml $out/
  '';
in
{
  auto-title = callPackage ./auto-title.nix { inherit installManifest; };
  # Fed unstable's rustPlatform (Rust 1.95+) — nixpkgs-25.11 ships 1.91,
  # too old for agent-quota's toolchain. See modules/packages/default.nix.
  agent-quota = callPackage ./agent-quota.nix { inherit installManifest rustPlatform; };
}
