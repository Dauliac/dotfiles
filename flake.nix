{
  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-stable";
    flake-parts.url = "github:hercules-ci/flake-parts";
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
  };
  outputs =
    inputs @ { nixpkgs
    , flake-parts
    , disko
    , home-manager
    , nixGL
    , nh
    , sops-nix
    , system-manager
    , catppuccin
    , ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } (_: {
      systems = [ "x86_64-linux" ];
      imports = [ ./modules ];
    });
}
