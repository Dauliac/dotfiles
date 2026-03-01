{ lib, ... }:
{
  options.dotfiles.systemManager = {
    sharedModules = lib.mkOption {
      type = lib.types.listOf lib.types.deferredModule;
      default = [ ];
      description = "System-manager modules shared across all hosts";
    };

    hostModules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf lib.types.deferredModule);
      default = { };
      description = "System-manager modules specific to each host";
    };
  };
}
