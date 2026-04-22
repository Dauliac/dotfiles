{
  config,
  inputs,
  ...
}:
let
  mkSystemManager =
    hostKey:
    inputs.system-manager.lib.makeSystemConfig {
      modules = [ config.flake.modules.systemManager."host-${hostKey}" ];
    };
in
{
  flake.systemConfigs = {
    "ML-PF59GCGW" = mkSystemManager "ml-pf59gcgw";
  };
}
