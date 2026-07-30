{
  config,
  inputs,
  ...
}:
let
  mkSystemManager =
    hostKey: extraModules:
    inputs.system-manager.lib.makeSystemConfig {
      modules = [ inputs.nlib.systemManagerModules.default config.flake.modules.systemManager."host-${hostKey}" ] ++ extraModules;
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
  ];

  homeManagerModules = [
    inputs.home-manager.nixosModules.home-manager
    sm.shell
    (
      { config, lib, ... }:
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
            imports = [ hmConfig.flake.modules.homeManager.user-juliendauliac ];
            nixpkgs.overlays = hmConfig.dotfiles.overlays;
            nixpkgs.config = hmConfig.dotfiles.nixpkgsConfig;
            # system-manager runs activation as a system service without a
            # D-Bus session bus, so dconf writes fail.  Disable dconf when
            # home-manager is driven by system-manager.
            dconf.enable = false;
            # Prevent nix-lib adapter from traversing programs.nixvim
            # (causes infinite recursion when nixvim is loaded alongside the adapter)
            nix-lib.enable = lib.mkForce false;
          };
        };
      }
    )
  ];
in
{
  flake.systemConfigs = {
    "ML-PF59GCGW" = mkSystemManager "ml-pf59gcgw" (cleanupModules ++ homeManagerModules);
  };
}
