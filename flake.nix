{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # Unstable — only cherry-picked for packages missing from release (e.g. acli, see modules/flake/overlays.nix).
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    nlib = {
      url = "github:Dauliac/nlib";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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
      url = "github:numtide/system-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ansnix = {
      url = "github:Dauliac/ansnix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.system-manager.follows = "system-manager";
      inputs.home-manager.follows = "home-manager";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-db = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      # Pinned: latest adds "antigravity" to supportedVscodes but home-manager lacks programs.antigravity
      url = "github:catppuccin/nix/ba73719e673e7c2d89ac2f8df0bc0d48983e4907";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixvim = {
      url = "github:nix-community/nixvim/nixos-26.05";
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
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprpanel = {
      url = "github:Jas-SinghFSU/HyprPanel";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.6.0";
    # rycee's firefox-addons, via the sourcehut mirror: the canonical
    # gitlab.com host 429s nix's unauthenticated tarball fetches.
    firefox-addons = {
      url = "sourcehut:~rycee/nur-expressions?dir=pkgs/firefox-addons";
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
    nixflix = {
      url = "github:kiriwalawren/nixflix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    xi = {
      # Pointed at the local checkout, pinned to a specific commit
      # rather than left bare: the xi repo has other work in progress
      # on disk at any given moment (other agent sessions, concurrent
      # branches), so nix's git+file fetcher treats the *whole repo*
      # as dirty and refuses to write a lock entry for a bare path or
      # `?ref=<branch>` reference - it is unlockable, not just
      # unreproducible. An explicit `?rev=` names an immutable, already
      # -committed object, so it locks fine regardless of what else in
      # the tree is currently uncommitted.
      #
      # Bump the rev by hand (`git -C .../xi rev-parse HEAD`) to pick
      # up newer xi commits; `nix flake update xi` alone will not move
      # it while the repo has anything else uncommitted.
      #
      # Revert to `github:Dauliac/xi/main` on a host that does not have
      # this checkout.
      url = "git+file:///home/juliendauliac/ghq/github.com/Dauliac/xi?rev=e4ee378c40c922e43f1736db91805a07021a4ace";
      # Xi calls the same underlying Dauliac/nlib repo by the alias
      # `nix-lib`, and the dotfiles calls it `nlib`. Without this follows,
      # nix imports the module twice under two attribute paths and
      # `options.nix-lib.lib` gets declared twice → eval error at
      # `xi home switch` time. Pinning here dedupes the identity so the
      # option is only declared once across the entire module graph.
      inputs.nix-lib.follows = "nlib";
    };
    aws-nix-cache = {
      url = "github:Dauliac/aws-nix-cache";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Nix packages for AI coding agents (herdr, beads, gascity, gastown, ...).
    # Not following nixpkgs so the numtide binary cache substitutes cleanly.
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
    # Anytype Toolbox — `anyr` CLI + client library (stevelr/anytype).
    # Umbrella Rust workspace: anyr / any-edit / anyback / any-mcp / anytype-api.
    # Not following nixpkgs — upstream uses nixpkgs-unstable + fenix for the
    # Rust toolchain pinned in rust-toolchain.toml (edition 2024), and following
    # would risk breaking their build.
    anytype-toolbox = {
      url = "github:stevelr/anytype/anyr-v0.5.3";
    };
    # Noctalia Shell plugin for the Anytype local HTTP API: watch
    # collections, quick-add, inert Kanban slot for phase 2. Pure QML,
    # so this input is a plain git tree (flake = false). Wired by
    # modules/home-manager/desktop/noctalia/anytype.nix: symlinks
    # ${anytype-noctalia}/plugin into ~/.config/noctalia/plugins/
    # anytype-noctalia and renders config.toml from a sops secret.
    anytype-noctalia = {
      url = "github:Dauliac/anytype-noctalia";
      flake = false;
    };
    # Declarative herdr home-manager module + typed programs.herdr.settings.*
    # + programs.herdr.plugins.<name>.source option. See openspec change
    # herdr-plugins-declarative. Pinned to sha instead of a branch — bumps
    # are reviewable diffs.
    herdr-nix = {
      url = "github:kevinpita/herdr-nix/953441303275da8196bad8e07362f8063cb58902";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Community-maintained Dendritic Nix distribution (import-trees + layers).
    # Import specific trees on demand from any flake-parts module, e.g.
    #   imports = [ inputs.dendrix.<repo>.<aspect> ];   # aspect import-tree
    #   imports = [ inputs.dendrix.<layer> ];           # community layer
    # See https://dendrix.denful.dev/ for the catalogue.
    dendrix = {
      url = "github:denful/dendrix";
      inputs.import-tree.follows = "import-tree";
    };
  };

  outputs =
    inputs@{
      import-tree,
      nlib,
      ...
    }:
    let
      # Filter out packages/ which contains overlays, not modules
      excludeFilter =
        path:
        let
          pathStr = toString path;
        in
        builtins.match ".*/packages/.*" pathStr != null;

      modulesTree = (import-tree.filterNot excludeFilter) ./modules;
    in
    nlib.lib.mkFlake
      {
        inherit inputs;
        inherit (inputs) flake-parts;
      }
      {
        systems = [ "x86_64-linux" ];

        imports = [
          inputs.flake-parts.flakeModules.modules
          inputs.flake-root.flakeModule
          inputs.home-manager.flakeModules.home-manager
          inputs.xi.flakeModule
          modulesTree
        ];
      };
}
