{
  # xi's nix-wrap replaces nix.package with a symlinkJoin that lacks
  # `pname`, which nix-daemon.nix:310 reads to check for lix. The real
  # host rebuilds via xi so the wrap matters there; the VM is throwaway
  # and only needs stock nix.
  #
  # xi's nix-lib adapter in HM scope traverses programs.nixvim to collect
  # nested libs, but nixvim's type is self-referential through
  # config.lib → infinite recursion. Mirror the system-manager guard at
  # modules/flake/system-configurations.nix:60-99: disable the adapter
  # and replay only the lib-function generation (no nested traversal).
  flake.modules.nixos.gary-vm-nix-tooling = { lib, ... }: {
    programs.xi.nix.wrapAlias = lib.mkForce false;

    home-manager.sharedModules = [
      (
        {
          config,
          lib,
          ...
        }:
        let
          defs = config.nix-lib.lib or { };
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
          fns = builtins.foldl' (
            acc: key: lib.recursiveUpdate acc (lib.setAttrByPath (lib.splitString "." key) flat.${key}.fn)
          ) { } (builtins.attrNames flat);
        in
        {
          nix-lib.enable = lib.mkForce false;
          lib = builtins.mapAttrs (_: v: if builtins.isFunction v then { __functor = _self: v; } else v) fns;
        }
      )
    ];
  };
}
