{ inputs, ...} : {
  flake.systemConfigs.ML-PF59GCGW = inputs.system-manager.lib.makeSystemConfig {
    modules = [
      ./system-manager
    ];
  };
}
