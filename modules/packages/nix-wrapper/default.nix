{
  writeShellApplication,
  nix,
  neix,
  nix-output-monitor,
  nix-tree,
  nvd,
  manix,
  statix,
  deadnix,
  nix-diff,
  comma,
  xi,
  nix-index,
  flake-checker,
  nix-du,
  nurl,
}:
writeShellApplication {
  name = "nx";
  runtimeInputs = [
    nix
    neix
    nix-output-monitor
    nix-tree
    nvd
    manix
    statix
    deadnix
    nix-diff
    comma
    xi
    nix-index
    flake-checker
    nix-du
    nurl
  ];
  text = builtins.readFile ./nx.sh;
}
