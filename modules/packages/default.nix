final: _prev:
let
  codemapPkg = final.callPackage ./codemap.nix { };
in
{
  codemap = codemapPkg;
  codemap-mcp = codemapPkg.mcp;
  anytype-cli = final.callPackage ./anytype-cli.nix { };
}
