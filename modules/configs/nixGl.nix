{ pkgs }:
# Should I in the feature return a set of { default, nixGLDefault, nixGLNvidia, nixGLNvidiaBumblebee, nixGLIntel, nixVulkanNvidia, nixVulkanIntel }?
# How to debug pkgs.nixgl in an overlay(?) in nix repl
# NOTE: maybe in future { wrapNixGLNvidia, wrapNixGLNvidiaBumblebee, wrapNixGLVulkanNvidia }
pkg:
let bins = "${pkg}/bin";
in
pkgs.buildEnv {
  name = "nixGL-${pkg.name}";
  paths = [ pkg ] ++ (map
    (bin:
      pkgs.hiPrio (pkgs.writeShellScriptBin bin ''
        exec -a "$0" "${pkgs.nixgl.nixGLIntel}/bin/nixGLIntel" "${bins}/${bin}" "$@"
      ''))
    (builtins.attrNames (builtins.readDir bins)));
}
