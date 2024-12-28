{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixGL = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    nh = {
      url = "github:viperML/nh";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-db = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    musnix = {
      url = "github:musnix/musnix";
    };
    sonicpi-nvim = {
      url = "github:magicmonty/sonicpi.nvim";
      flake = false;
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
    zen-browser.url = "github:MarceColl/zen-browser-flake";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
  outputs =
    inputs@{
      nixpkgs,
      flake-parts,
      disko,
      home-manager,
      nixGL,
      nh,
      sops-nix,
      system-manager,
      catppuccin,
      nixvim,
      sonicpi-nvim,
      lanzaboote,
      lsp-lens-nvim,
      yaml-companion-nvim,
      musnix,
      zen-browser,
      hyprpanel,
      treefmt-nix,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (_: {
      systems = [ "x86_64-linux" ];
      imports = [ ./modules ];
    });
}
