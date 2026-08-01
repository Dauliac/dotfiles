_: {
  flake.modules.systemManager.shell-stubs = { lib, ... }: {
    # system-manager reuses NixOS users-groups.nix which asserts
    # programs.<shell>.enable for zsh/fish/xonsh, but system-manager
    # doesn't import the NixOS programs module. Provide stub options.
    options.programs.zsh.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    options.programs.fish.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    options.programs.xonsh.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };
}
