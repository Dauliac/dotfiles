{
  config,
  inputs,
  ...
}:
let
  mkSystemManager =
    hostKey: extraModules:
    inputs.system-manager.lib.makeSystemConfig {
      modules = [ config.flake.modules.systemManager."host-${hostKey}" ] ++ extraModules;
    };

  sm = config.flake.modules.systemManager;
  cleanupModules = [
    sm."cleanup-nix"
    sm."cleanup-docker"
    sm."cleanup-apt"
    sm."cleanup-flatpak"
    sm."cleanup-tmp"
    sm."cleanup-journal"
  ];
in
{
  flake.systemConfigs = {
    "ML-PF59GCGW" = mkSystemManager "ml-pf59gcgw" cleanupModules;
  };
}
