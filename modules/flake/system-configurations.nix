{
  config,
  inputs,
  ...
}:
let
  inherit (inputs.system-manager.lib) makeSystemConfig;

  mkSystemManager =
    hostname:
    makeSystemConfig {
      modules =
        config.dotfiles.systemManager.sharedModules
        ++ (config.dotfiles.systemManager.hostModules.${hostname} or [ ]);
    };
in
{
  flake.systemConfigs = {
    "ML-PF59GCGW" = mkSystemManager "ML-PF59GCGW";
  };
}
