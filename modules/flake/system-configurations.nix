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
    (
      {
        config,
        ...
      }:
      {
        nix.enable = true;
        services.userborn.enable = true;

        users.groups.juliendauliac.gid = 1001;
        users.users.juliendauliac = {
          isNormalUser = true;
          uid = 1001;
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
      }
    )
  ];
in
{
  flake.systemConfigs = {
    "ML-PF59GCGW" = mkSystemManager "ml-pf59gcgw" (cleanupModules ++ homeManagerModules);
    "ML-PF603JJ8" = mkSystemManager "ml-pf603jj8" (cleanupModules ++ homeManagerModules);
  };
}
