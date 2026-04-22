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
  mempalace = final.callPackage ./mempalace.nix { };
  neix = inputs.neix.packages.${system}.default;
  nx = final.callPackage ./nix-wrapper { };
  mermaid-ascii = final.callPackage ./mermaid-ascii.nix { };
  mmdr = final.callPackage ./mmdr.nix { };
}
