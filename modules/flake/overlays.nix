{
  lib,
  inputs,
  ...
}:
let
  # Custom packages overlay - located in modules/packages/
  customPackagesOverlay = import ../packages { inherit inputs; };

  # Compatibility overlay: combines individual mcp-server-* packages
  # into a single mcp-servers package expected by mcps.nix.
  # Sourced from nixpkgs-unstable because the 2026.8.31 server bump requires
  # python3Packages.mcp >= 1.29.0, which only unstable ships (25.11 has 1.26.0).
  mcpServersCompatOverlay = final: _prev:
    let
      unstablePkgs = import inputs.nixpkgs-unstable {
        inherit (final.stdenv.hostPlatform) system;
        config.allowUnfree = true;
      };
    in
    {
      mcp-servers = final.symlinkJoin {
        name = "mcp-servers";
        paths = [
          unstablePkgs.mcp-server-fetch
          unstablePkgs.mcp-server-filesystem
          unstablePkgs.mcp-server-git
          unstablePkgs.mcp-server-sequential-thinking
          unstablePkgs.mcp-server-memory
        ];
      };
    };
in
{
  options.dotfiles.overlays = lib.mkOption {
    type = lib.types.listOf lib.types.raw;
    default = [
      inputs.nixGL.overlay
      inputs.mcp-servers-nix.overlays.default # Provides individual mcp-server-* packages
      mcpServersCompatOverlay # Combines them into pkgs.mcp-servers for mcps.nix
      inputs.mcps.overlays.default
      inputs.xi.overlays.default # adds pkgs.xi
      (final: prev: { comma = prev.comma.override { nix = final.lix; }; })
      customPackagesOverlay
    ];
    description = "Overlays to apply to nixpkgs";
  };

  options.dotfiles.nixpkgsConfig = lib.mkOption {
    type = lib.types.attrs;
    default = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "qtwebengine-5.15.19"
        "pnpm-9.15.9"
      ];
    };
    description = "Nixpkgs config settings";
  };
}
