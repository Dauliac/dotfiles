{ pkgs }:
let
  bins = "${pkg}/bin";
in
{
  programs.nixGl = rec {
    package = pkgs.nixgl.nixGLIntel;
    wrapper = pkg:
      pkgs.buildEnv {
        name = "nixGL-${pkg.name}";
        paths =
          [ pkg ]
          ++ (map
            (bin:
              pkgs.hiPrio (pkgs.writeShellScriptBin bin ''
                exec -a "$0" "${package}/bin/nixGLIntel" "${bins}/${bin}" "$@"
              ''))
            (builtins.attrNames (builtins.readDir bins)));
      };
  };
}
