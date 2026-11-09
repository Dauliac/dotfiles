{
  config,
  inputs,
  ...
}:
let
  mkSystemManager =
    hostKey: extraModules:
    inputs.system-manager.lib.makeSystemConfig {
      modules = [
        inputs.nlib.systemManagerModules.default
        config.flake.modules.systemManager."host-${hostKey}"
      ]
      ++ extraModules;
    };

  sm = config.flake.modules.systemManager;
  hmConfig = config;

  cleanupModules = [
    sm."cleanup-nix"
    sm."cleanup-docker"
    sm."cleanup-apt"
    sm."cleanup-flatpak"
    sm."cleanup-tmp"
    sm."cleanup-journal"
    sm."login-shells"
  ];

  homeManagerModules = [
    inputs.home-manager.nixosModules.home-manager
    sm.shell
    ({ config, ... }: {
      nix.enable = true;
      services.userborn.enable = true;

      # uid/gid MUST match the pre-existing Debian account (`getent passwd
      # juliendauliac`), not an arbitrary NixOS-style 1001.  home-manager's
      # activation script asserts `checkStringEq UID "$(id -u)" <uid>` and
      # hard-exits 1 on mismatch, so a wrong value here silently kills
      # home-manager-juliendauliac.service on every `xi system switch`
      # ("UID is \"1011\", expected \"1001\"" in the journal) while the
      # switch itself still reports success.
      users.groups.juliendauliac.gid = 1012;
      users.users.juliendauliac = {
        isNormalUser = true;
        uid = 1011;
        group = "juliendauliac";
        home = "/home/juliendauliac";
        createHome = true;
        shell = config.systemConstants.shell.package;
      };

      home-manager = {
        useGlobalPkgs = false;
        useUserPackages = false;
        backupFileExtension = "bak";
        extraSpecialArgs = { inherit inputs; };
        users.juliendauliac = {
          imports = [
            hmConfig.flake.modules.homeManager.user-juliendauliac
            # The xi nix-lib adapter traverses programs.nixvim to collect
            # nested libs, but nixvim's type is self-referential through
            # config.lib → infinite recursion.  Disable the adapter and
            # replay only the lib-function generation (no nested traversal).
            (
              {
                config,
                lib,
                ...
              }:
              let
                defs = config.nix-lib.lib or { };
                # Flatten nested lib defs → { "a.b" = { fn = …; }; … }
                flatten =
                  prefix: attrs:
                  builtins.foldl' (
                    acc: name:
                    let
                      v = attrs.${name};
                      key = if prefix == "" then name else "${prefix}.${name}";
                    in
                    if v ? fn then
                      acc // { ${key} = v; }
                    else if builtins.isAttrs v then
                      acc // (flatten key v)
                    else
                      acc
                  ) { } (builtins.attrNames attrs);
                flat = flatten "" defs;
                # Rebuild nested attrset of bare functions
                fns = builtins.foldl' (
                  acc: key: lib.recursiveUpdate acc (lib.setAttrByPath (lib.splitString "." key) flat.${key}.fn)
                ) { } (builtins.attrNames flat);
              in
              {
                nix-lib.enable = lib.mkForce false;
                # home-manager's config.lib rejects plain functions; wrap them
                lib = builtins.mapAttrs (_: v: if builtins.isFunction v then { __functor = _self: v; } else v) fns;
              }
            )
          ];
          nixpkgs.overlays = hmConfig.dotfiles.overlays;
          nixpkgs.config = hmConfig.dotfiles.nixpkgsConfig;
          # system-manager runs activation as a system service without a
          # D-Bus session bus, so dconf writes fail.  Disable dconf when
          # home-manager is driven by system-manager.
          dconf.enable = false;
        };
      };
    })
  ];

  # `inputs.xi.nixosModules.default` can't be imported here: see
  # xi-9m39 (fixed upstream by shipping the narrower
  # `nixosModules.sources` below, rather than making `.default` itself
  # tolerant of a consumer's own nix-lib head). `.sources` is the same
  # import list as `.default` minus `inputs.nix-lib.nixosModules.default`
  # (already provided by `inputs.nlib.systemManagerModules.default`
  # above, via `nix-lib.follows = "nlib"`) and minus
  # `shell-hook.nix`/`completion.nix` (the two files that assign option
  # paths system-manager's reduced NixOS surface doesn't declare).
  #
  # `remote`/`branch` match what `xi system switch` already adopted on
  # ML-PF603JJ8 (`xi system status` reports this exact remote) - this
  # just gives that state a declarative Nix-module source of truth
  # instead of living only in `.xi.toml`. `workingDir` is deliberately
  # NOT set: `programs.xi.sources.workingDir` is user-scope only
  # (modules/nixos/sources.nix asserts this), unlike the
  # `user-juliendauliac` home-manager config in
  # modules/home.juliendauliac/default.nix, which does use it.
  # `gitops.enable` is on here (unlike that same user-scope config,
  # which deliberately leaves it off to avoid racing this host's
  # system-manager-driven activation) since this scope - not the
  # embedded home-manager - is the one actually owning activation.
  xiSourcesModules = [
    inputs.xi.nixosModules.sources
    {
      programs.xi = {
        enable = true;
        sources = {
          enable = true;
          remote = "ssh://github.com/Dauliac/dotfiles";
          branch = "master";
          gitops.enable = true;
        };
      };
    }
  ];
in
{
  flake.systemConfigs = {
    "ML-PF59GCGW" = mkSystemManager "ml-pf59gcgw" (cleanupModules ++ homeManagerModules);
    "ML-PF603JJ8" = mkSystemManager "ml-pf603jj8" (
      cleanupModules ++ homeManagerModules ++ xiSourcesModules
    );
  };
}
