{ inputs }:
final: _prev:
let
  codemapPkg = final.callPackage ./codemap.nix { };
  inherit (final.stdenv.hostPlatform) system;
in
{
  codemap = codemapPkg;
  codemap-mcp = codemapPkg.mcp;
  anytype-cli = final.callPackage ./anytype-cli.nix { };
  neix = inputs.neix.packages.${system}.default;
  nx = final.callPackage ./nix-wrapper { };
}
