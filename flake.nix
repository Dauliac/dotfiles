{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-fast-build.url = "github:Mic92/nix-fast-build";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixGL = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    nix-index-db = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    nixvim = {
      url = "github:nix-community/nixvim/nixos-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
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
    commander-nvim = {
      url = "github:FeiyouG/commander.nvim";
      flake = false;
    };
    zen-browser.url = "github:MarceColl/zen-browser-flake";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (_: {
      systems = [ "x86_64-linux" ];
      imports = [ ./modules ];
    });
}
