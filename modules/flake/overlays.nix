{
  lib,
  inputs,
  ...
}:
let
  # Custom packages overlay - located in modules/packages/
  customPackagesOverlay = import ../packages { inherit inputs; };

  # Compatibility overlay: combines individual mcp-server-* packages
  # into a single mcp-servers package expected by mcps.nix
  mcpServersCompatOverlay = final: _prev: {
    mcp-servers = final.symlinkJoin {
      name = "mcp-servers";
      paths = [
        final.mcp-server-fetch
        final.mcp-server-filesystem
        final.mcp-server-git
        # mcp-server-time removed: requires mcp>=1.23.0 but nixpkgs only has 1.15.0
        final.mcp-server-sequential-thinking
        final.mcp-server-memory
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
      ];
    };
    description = "Nixpkgs config settings";
  };
}
