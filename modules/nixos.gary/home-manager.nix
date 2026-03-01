{
  lib,
  ...
}:
{
  # Configure home-manager users for gary host
  # The actual home-manager modules are passed via home-manager.sharedModules
  # in nixos-configurations.nix (from config.dotfiles.home.sharedModules)
  config.dotfiles.nixos.hostModules.gary = lib.mkAfter [
    (_: {
      # Users gary and dauliac get sharedModules automatically
      # home.stateVersion is required
      home-manager.users.gary = {
        home.stateVersion = "25.05";
      };
      home-manager.users.dauliac = {
        home.stateVersion = "25.05";
      };
    })
  ];
}
