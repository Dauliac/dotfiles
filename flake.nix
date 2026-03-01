{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nlib = {
      url = "github:Dauliac/nlib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-auth.url = "github:numtide/nix-auth";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    betterfox-nix = {
      url = "github:HeitorAugustoLN/betterfox-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    omnix = {
      url = "github:juspay/omnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixGL = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    nix-index-db = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lsp-lens-nvim = {
      url = "github:VidocqH/lsp-lens.nvim";
      flake = false;
    };
    yaml-companion-nvim = {
      url = "github:someone-stole-my-name/yaml-companion.nvim";
      flake = false;
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    commander-nvim = {
      url = "github:FeiyouG/commander.nvim";
      flake = false;
    };
    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
    };
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    };
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devour-flake = {
      url = "github:srid/devour-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake.follows = "";
    };
    flake-root = {
      url = "github:srid/flake-root";
    };
    neix = {
      url = "github:Hovirix/neix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcps = {
      url = "github:roman/mcps.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mcp-servers-nix = {
      url = "github:natsukium/mcp-servers-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      import-tree,
      ...
    }:
    let
      # Filter out paths that shouldn't be imported as flake-parts modules
      excludeFilter =
        path:
        let
          pathStr = builtins.toString path;
          name = builtins.baseNameOf pathStr;
        in
        # Exclude old profile directories (now using dot-notation aspects)
        builtins.match ".*profiles.*" pathStr != null
        # Exclude packages directory (contains overlays, not modules)
        || builtins.match ".*/packages/.*" pathStr != null
        # Exclude old flake-parts directory (now using per-system/)
        || builtins.match ".*/flake-parts/.*" pathStr != null
        # Exclude old system-manager/default.nix
        || builtins.match ".*/system-manager/default\\.nix$" pathStr != null
        # Exclude old top-level module files
        || name == "modules.nix"
        || name == "nixos.nix"
        || name == "home-manager.nix"
        || name == "system-manager.nix"
        # Exclude options directory - we'll import it explicitly first
        || builtins.match ".*/options/.*" pathStr != null;

      # Create the import-tree module for non-options content
      modulesTree = (import-tree.filterNot excludeFilter) ./modules;

      # Import options tree separately to ensure it's loaded first
      optionsTree = import-tree ./modules/options;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];

      # Import options first, then all other modules
      imports = [
        inputs.flake-root.flakeModule
        inputs.home-manager.flakeModules.home-manager
        optionsTree
        modulesTree
      ];
    };
}
