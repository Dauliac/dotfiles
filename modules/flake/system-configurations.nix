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

  # NOT wiring `inputs.xi.nixosModules.default` into system-manager
  # scope here: it hits two real incompatibilities with
  # system-manager's reduced NixOS option surface.
  #
  # 1. modules/nixos/shell-hook.nix assigns
  #    `environment.interactiveShellInit` /
  #    `programs.fish.interactiveShellInit`, neither of which
  #    system-manager declares - a module-merge error even with
  #    `shellHook.enable` at its default `false`, since `lib.mkIf`
  #    only gates the *value*, not whether the *option path* has to
  #    exist. Worked around locally with a two-line option stub, that
  #    part alone is fine.
  # 2. `nixosModules.default` also imports `inputs.nix-lib.nixosModules.default`
  #    (xi's own copy of the nix-lib framework's NixOS head), which
  #    then double-declares `nix-lib.scanNestedSystems` against
  #    `inputs.nlib.systemManagerModules.default` (already imported
  #    unconditionally for every host by `mkSystemManager` above) -
  #    same underlying flake (`nix-lib.follows = "nlib"`), two
  #    different "class" heads, same option path. No `lib.mkForce`
  #    equivalent exists for a *declaration* clash, only for values,
  #    so there is no clean per-host workaround for this one.
  #
  # Hand-picking xi's individual nixos/*.nix files instead of the
  # aggregate just trades these for a different cascade
  # (modules/nixos/package.nix alone needs settings.nix's shared
  # types too). Real fix belongs in xi itself (nixosModules.default
  # should not unconditionally pull in a nix-lib head the consumer may
  # already have), filed as xi-nixos-module-system-manager-clash - see
  # that bead before trying this again. `programs.xi.sources` at
  # system scope stays on the CLI/state-dir rungs for now, which is
  # already what `xi system switch` adopted and `xi system status`
  # reads.
in
{
  flake.systemConfigs = {
    "ML-PF59GCGW" = mkSystemManager "ml-pf59gcgw" (cleanupModules ++ homeManagerModules);
    "ML-PF603JJ8" = mkSystemManager "ml-pf603jj8" (cleanupModules ++ homeManagerModules);
  };
}
