{
  flake.modules.homeManager.ai-packages =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        codemap
        codemap-mcp
        anytype-cli
        # mempalace  # disabled: pyproject format mismatch, needs pyproject = true upstream
        mermaid-ascii
        # mmdr  # disabled: fetchCargoVendor 403 from crates.io (default python-requests UA blocked by data-access policy)
      ];
    };
}
